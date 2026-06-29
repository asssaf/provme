import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre
import lustre/attribute.{
  attribute, checked, class, id, placeholder, style, type_, value,
}
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{
  button, div, h1, h3, header, input, label, p, span, table, tbody, td, th, thead,
  tr,
}
import lustre/element/svg
import lustre/event.{on_check, on_click, on_input}

// TYPES & MODELS

pub type SSHConfig {
  SSHConfig(user: String, port: Int, host_key: String)
}

pub type Client {
  Client(client_id: String, ip: String, ssh: SSHConfig, created_at: String)
}

pub type ToastType {
  ToastSuccess
  ToastError
  ToastInfo
}

pub type Toast {
  Toast(id: Int, message: String, type_: ToastType)
}

pub type Model {
  Model(
    registrations: List(Client),
    search_query: String,
    auto_refresh: Bool,
    key_modal: Option(String),
    toasts: List(Toast),
    next_toast_id: Int,
    last_activity: String,
    is_refreshing: Bool,
  )
}

// MESSAGES

pub type Msg {
  FetchData
  FetchedData(Dynamic)
  FailedFetch(String)
  SearchChanged(String)
  AutoRefreshToggled
  Tick
  TriggerSimulation
  Simulated(Dynamic)
  FailedSimulation(String)
  DeleteClient(String)
  Deleted(String, Dynamic)
  FailedDelete(String)
  OpenKeyModal(String)
  CloseModal
  DismissToast(Int)
  CopyText(String)
  CopiedText
  NoOp
}

// FFI IMPORTS

@external(javascript, "./ffi.mjs", "fetch_json")
pub fn fetch_json(
  url: String,
  method: String,
  body: String,
  on_success: fn(Dynamic) -> Nil,
  on_error: fn(String) -> Nil,
) -> Nil

@external(javascript, "./ffi.mjs", "copy_to_clipboard")
pub fn copy_to_clipboard(text: String, on_success: fn() -> Nil) -> Nil

@external(javascript, "./ffi.mjs", "start_timer")
pub fn start_timer(ms: Int, callback: fn() -> Nil) -> Nil

@external(javascript, "./ffi.mjs", "simulate_registration")
pub fn simulate_registration(
  on_success: fn(Dynamic) -> Nil,
  on_error: fn(String) -> Nil,
) -> Nil

@external(javascript, "./ffi.mjs", "run_after")
pub fn run_after(ms: Int, callback: fn() -> Nil) -> Nil

// EFFECT HELPERS

pub fn fetch_data_effect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    fetch_json(
      "/v1/registrations",
      "GET",
      "",
      fn(data) { dispatch(FetchedData(data)) },
      fn(err) { dispatch(FailedFetch(err)) },
    )
  })
}

pub fn delete_client_effect(client_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    fetch_json(
      "/v1/registrations/" <> client_id,
      "DELETE",
      "",
      fn(data) { dispatch(Deleted(client_id, data)) },
      fn(err) { dispatch(FailedDelete(err)) },
    )
  })
}

pub fn simulate_registration_effect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    simulate_registration(
      fn(data) { dispatch(Simulated(data)) },
      fn(err) { dispatch(FailedSimulation(err)) },
    )
  })
}

pub fn copy_text_effect(text: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    copy_to_clipboard(text, fn() { dispatch(CopiedText) })
  })
}

pub fn start_timer_effect(ms: Int, tick_msg: Msg) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    start_timer(ms, fn() { dispatch(tick_msg) })
  })
}

pub fn add_toast_effect(toast_id: Int) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    run_after(3000, fn() { dispatch(DismissToast(toast_id)) })
  })
}

// TOAST HELPER

fn add_toast(
  message: String,
  type_: ToastType,
  model: Model,
) -> #(Model, Effect(Msg)) {
  let toast_id = model.next_toast_id
  let new_toast = Toast(id: toast_id, message: message, type_: type_)
  let new_toasts = list.append(model.toasts, [new_toast])
  #(
    Model(..model, toasts: new_toasts, next_toast_id: toast_id + 1),
    add_toast_effect(toast_id),
  )
}

// INITIALIZATION

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  #(
    Model(
      registrations: [],
      search_query: "",
      auto_refresh: True,
      key_modal: None,
      toasts: [],
      next_toast_id: 1,
      last_activity: "Never",
      is_refreshing: False,
    ),
    effect.batch([fetch_data_effect(), start_timer_effect(5000, Tick)]),
  )
}

// UPDATE

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    FetchData -> #(Model(..model, is_refreshing: True), fetch_data_effect())

    FetchedData(dynamic_data) -> {
      let result = decode.run(dynamic_data, clients_list_decoder())
      case result {
        Ok(data) -> {
          let sorted =
            list.sort(data, fn(a, b) {
              string.compare(b.created_at, a.created_at)
            })

          let last_act = case list.first(sorted) {
            Ok(c) -> c.created_at
            Error(_) -> model.last_activity
          }

          #(
            Model(
              ..model,
              registrations: sorted,
              is_refreshing: False,
              last_activity: last_act,
            ),
            effect.none(),
          )
        }
        Error(_) -> {
          let #(new_model, cmd) =
            add_toast("Failed to parse registrations data", ToastError, model)
          #(Model(..new_model, is_refreshing: False), cmd)
        }
      }
    }

    FailedFetch(_) -> {
      let #(new_model, cmd) =
        add_toast("Connection to server failed", ToastError, model)
      #(Model(..new_model, is_refreshing: False), cmd)
    }

    SearchChanged(query) -> #(
      Model(..model, search_query: query),
      effect.none(),
    )

    AutoRefreshToggled -> #(
      Model(..model, auto_refresh: !model.auto_refresh),
      effect.none(),
    )

    Tick -> {
      case model.auto_refresh {
        True -> #(model, fetch_data_effect())
        False -> #(model, effect.none())
      }
    }

    TriggerSimulation -> #(model, simulate_registration_effect())

    Simulated(_) -> {
      let #(new_model, cmd) =
        add_toast("Simulation: Registered new client", ToastSuccess, model)
      #(new_model, effect.batch([cmd, fetch_data_effect()]))
    }

    FailedSimulation(err) -> {
      let #(new_model, cmd) =
        add_toast("Failed to simulate registration: " <> err, ToastError, model)
      #(new_model, cmd)
    }

    DeleteClient(client_id) -> #(model, delete_client_effect(client_id))

    Deleted(_, _) -> {
      let #(new_model, cmd) =
        add_toast("Client deregistered successfully", ToastSuccess, model)
      #(new_model, effect.batch([cmd, fetch_data_effect()]))
    }

    FailedDelete(err) -> {
      let #(new_model, cmd) =
        add_toast("Failed to delete client: " <> err, ToastError, model)
      #(new_model, cmd)
    }

    OpenKeyModal(key) -> #(Model(..model, key_modal: Some(key)), effect.none())

    CloseModal -> #(Model(..model, key_modal: None), effect.none())

    DismissToast(toast_id) -> {
      let filtered = list.filter(model.toasts, fn(t) { t.id != toast_id })
      #(Model(..model, toasts: filtered), effect.none())
    }

    CopyText(text) -> #(model, copy_text_effect(text))

    CopiedText -> {
      let #(new_model, cmd) =
        add_toast("Copied to clipboard!", ToastSuccess, model)
      #(new_model, cmd)
    }

    NoOp -> #(model, effect.none())
  }
}

// VIEW

fn view(model: Model) -> Element(Msg) {
  let filtered_clients =
    list.filter(model.registrations, filter_client(model.search_query))

  let unique_ips =
    list.map(model.registrations, fn(r) { r.ip })
    |> unique_list
    |> list.length

  let last_act_text = case model.last_activity {
    "Never" -> "Never"
    iso -> format_time_str(iso)
  }

  let refresh_btn_class =
    "btn btn-secondary btn-icon-only"
    <> case model.is_refreshing {
      True -> " rotating"
      False -> ""
    }

  div([class("container")], [
    // Header
    header([], [
      div([class("logo-section")], [
        div([class("logo-icon")], [svg_logo()]),
        div([class("title-group")], [
          h1([], [text("PROVME Admin")]),
          p([], [text("Client Registration Management Portal (Gleam Version)")]),
        ]),
      ]),
      div([class("status-badge")], [
        span([class("status-dot")], []),
        span([], [text("System Operational")]),
      ]),
    ]),
    // Stats Grid
    div([class("stats-grid")], [
      stat_card(
        "Total Clients",
        int.to_string(list.length(model.registrations)),
        "Registered in-memory",
        "var(--primary)",
        total_clients_icon(),
      ),
      stat_card(
        "Unique IPs",
        int.to_string(unique_ips),
        "Distinct client locations",
        "var(--cyan)",
        unique_ips_icon(),
      ),
      stat_card(
        "Last Activity",
        last_act_text,
        "Latest registration event",
        "var(--emerald)",
        last_activity_icon(),
      ),
    ]),
    // Controls Toolbar
    div([class("controls-row")], [
      div([class("search-wrapper")], [
        span([class("search-icon")], [search_icon()]),
        input([
          type_("text"),
          class("search-input"),
          placeholder("Search by Client ID, IP, SSH user..."),
          value(model.search_query),
          on_input(SearchChanged),
        ]),
      ]),
      div([class("actions-group")], [
        div([class("refresh-toggle-container")], [
          span([], [text("Auto-refresh")]),
          label([class("switch")], [
            input([
              type_("checkbox"),
              checked(model.auto_refresh),
              on_check(fn(_) { AutoRefreshToggled }),
            ]),
            span([class("slider")], []),
          ]),
        ]),
        button(
          [
            class(refresh_btn_class),
            attribute("title", "Refresh Now"),
            on_click(FetchData),
          ],
          [refresh_icon()],
        ),
        button([class("btn btn-primary"), on_click(TriggerSimulation)], [
          simulate_icon(),
          text("Simulate Registration"),
        ]),
      ]),
    ]),
    // Table
    div([class("table-container")], [
      table([id("clients-table")], [
        thead([], [
          tr([], [
            th([], [text("Client ID")]),
            th([], [text("IP Address")]),
            th([], [text("SSH Access")]),
            th([], [text("Host Key Preview")]),
            th([], [text("Registered At")]),
            th([style("text-align", "right")], [text("Actions")]),
          ]),
        ]),
        tbody([], list.map(filtered_clients, view_client_row)),
      ]),
      case list.is_empty(filtered_clients) {
        True -> view_empty_state()
        False -> element.none()
      },
    ]),
    // Modal
    case model.key_modal {
      Some(key) -> view_key_modal(key)
      None -> element.none()
    },
    // Toasts
    div([class("toast-container")], list.map(model.toasts, view_toast)),
  ])
}

// VIEW HELPERS

fn stat_card(
  title_text: String,
  val: String,
  desc: String,
  color: String,
  icon: Element(Msg),
) -> Element(Msg) {
  div([class("stat-card"), style("--card-accent", color)], [
    div([class("stat-info")], [
      h3([], [text(title_text)]),
      div([class("stat-value")], [text(val)]),
      div([class("stat-desc")], [text(desc)]),
    ]),
    div([class("stat-icon-wrapper")], [icon]),
  ])
}

fn view_client_row(client: Client) -> Element(Msg) {
  let short_id = case string.length(client.client_id) > 8 {
    True -> string.slice(client.client_id, 0, 8) <> "..."
    False -> client.client_id
  }

  tr([id("row-" <> client.client_id)], [
    td([], [
      div([class("td-client-id")], [
        span([class("client-id-text"), attribute("title", client.client_id)], [
          text(short_id),
        ]),
        button(
          [
            class("copy-btn"),
            attribute("title", "Copy Client ID"),
            on_click(CopyText(client.client_id)),
          ],
          [copy_icon()],
        ),
      ]),
    ]),
    td([], [span([class("td-ip")], [text(client.ip)])]),
    td([], [
      span([class("ssh-badge-user")], [text(client.ssh.user)]),
      span([class("ssh-badge-port")], [
        text(":" <> int.to_string(client.ssh.port)),
      ]),
    ]),
    td([], [
      span([class("key-preview"), attribute("title", client.ssh.host_key)], [
        text(client.ssh.host_key),
      ]),
      button(
        [
          class("key-action-btn"),
          on_click(OpenKeyModal(client.ssh.host_key)),
        ],
        [text("View Key")],
      ),
    ]),
    td([], [
      span([class("time-text"), attribute("title", client.created_at)], [
        text(format_time_str(client.created_at)),
      ]),
    ]),
    td([style("text-align", "right")], [
      button(
        [
          class("btn-danger-link"),
          attribute("title", "Deregister Client"),
          on_click(DeleteClient(client.client_id)),
        ],
        [delete_icon()],
      ),
    ]),
  ])
}

fn view_empty_state() -> Element(Msg) {
  div([id("empty-state-view"), class("empty-state")], [
    div([class("empty-icon")], [
      svg.svg(
        [
          attribute("viewBox", "0 0 24 24"),
          attribute("fill", "none"),
          attribute("stroke", "currentColor"),
          attribute("stroke-width", "2"),
          attribute("stroke-linecap", "round"),
          attribute("stroke-linejoin", "round"),
        ],
        [
          svg.path([attribute("d", "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2")]),
          svg.circle([
            attribute("cx", "9"),
            attribute("cy", "7"),
            attribute("r", "4"),
          ]),
          svg.path([attribute("d", "M23 21v-2a4 4 0 0 0-3-3.87")]),
          svg.path([attribute("d", "M16 3.13a4 4 0 0 1 0 7.75")]),
        ],
      ),
    ]),
    h3([], [text("No registered clients")]),
    p([], [
      text(
        "Use the simulator button above or send a POST request to /v1/register to register new devices.",
      ),
    ]),
  ])
}

fn view_key_modal(key: String) -> Element(Msg) {
  div(
    [id("key-modal"), class("modal-overlay open"), on_click(CloseModal)],
    [
      div([class("modal"), attribute("onclick", "event.stopPropagation()")], [
        div([class("modal-header")], [
          h3([], [text("SSH Host Key Details")]),
          button(
            [class("modal-close"), id("modal-close-btn"), on_click(CloseModal)],
            [
              svg.svg([attribute("viewBox", "0 0 24 24")], [
                svg.line([
                  attribute("x1", "18"),
                  attribute("y1", "6"),
                  attribute("x2", "6"),
                  attribute("y2", "18"),
                ]),
                svg.line([
                  attribute("x1", "6"),
                  attribute("y1", "6"),
                  attribute("x2", "18"),
                  attribute("y2", "18"),
                ]),
              ]),
            ],
          ),
        ]),
        div([class("modal-body")], [
          p(
            [
              style("font-size", "0.85rem"),
              style("color", "var(--text-secondary)"),
              style("margin-bottom", "0.75rem"),
            ],
            [text("Full host key for this registration:")],
          ),
          div([class("key-textarea-wrapper")], [
            div([id("modal-key-content"), class("key-text-box")], [text(key)]),
          ]),
        ]),
        div([class("modal-footer")], [
          button(
            [
              class("btn btn-secondary"),
              id("modal-cancel-btn"),
              on_click(CloseModal),
            ],
            [text("Close")],
          ),
          button(
            [
              class("btn btn-primary"),
              id("modal-copy-btn"),
              on_click(CopyText(key)),
            ],
            [
              svg.svg(
                [
                  attribute("viewBox", "0 0 24 24"),
                  style("width", "16px"),
                  style("height", "16px"),
                  style("display", "inline-block"),
                  style("vertical-align", "middle"),
                  style("margin-right", "4px"),
                ],
                [
                  svg.rect([
                    attribute("x", "9"),
                    attribute("y", "9"),
                    attribute("width", "13"),
                    attribute("height", "13"),
                    attribute("rx", "2"),
                    attribute("ry", "2"),
                  ]),
                  svg.path([
                    attribute(
                      "d",
                      "M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1",
                    ),
                  ]),
                ],
              ),
              text("Copy Key"),
            ],
          ),
        ]),
      ]),
    ],
  )
}

fn view_toast(toast: Toast) -> Element(Msg) {
  let toast_class = case toast.type_ {
    ToastSuccess -> "toast toast-success show"
    ToastError -> "toast toast-error show"
    ToastInfo -> "toast toast-info show"
  }

  let icon_svg = case toast.type_ {
    ToastSuccess ->
      svg.svg(
        [
          attribute("viewBox", "0 0 24 24"),
          attribute("fill", "none"),
          attribute("stroke", "currentColor"),
          attribute("stroke-width", "2.5"),
          style("width", "14px"),
          style("height", "14px"),
        ],
        [svg.polyline([attribute("points", "20 6 9 17 4 12")])],
      )

    _ ->
      svg.svg(
        [
          attribute("viewBox", "0 0 24 24"),
          attribute("fill", "none"),
          attribute("stroke", "currentColor"),
          attribute("stroke-width", "2.5"),
          style("width", "14px"),
          style("height", "14px"),
        ],
        [
          svg.line([
            attribute("x1", "18"),
            attribute("y1", "6"),
            attribute("x2", "6"),
            attribute("y2", "18"),
          ]),
          svg.line([
            attribute("x1", "6"),
            attribute("y1", "6"),
            attribute("x2", "18"),
            attribute("y2", "18"),
          ]),
        ],
      )
  }

  div([class(toast_class)], [
    div([class("toast-icon")], [icon_svg]),
    div([class("toast-message")], [text(toast.message)]),
  ])
}

// SVG ICON HELPERS

fn svg_logo() -> Element(Msg) {
  svg.svg(
    [attribute("viewBox", "0 0 24 24")],
    [
      svg.path([
        attribute(
          "d",
          "M12 2L2 22h20L12 2zm0 3.99L19.53 19H4.47L12 5.99zM13 16h-2v2h2v-2zm0-6h-2v4h2v-4z",
        ),
      ]),
    ],
  )
}

fn total_clients_icon() -> Element(Msg) {
  svg.svg(
    [
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "none"),
      attribute("stroke", "currentColor"),
      attribute("stroke-width", "2"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-linejoin", "round"),
    ],
    [
      svg.path([attribute("d", "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2")]),
      svg.circle([
        attribute("cx", "9"),
        attribute("cy", "7"),
        attribute("r", "4"),
      ]),
      svg.path([attribute("d", "M23 21v-2a4 4 0 0 0-3-3.87")]),
      svg.path([attribute("d", "M16 3.13a4 4 0 0 1 0 7.75")]),
    ],
  )
}

fn unique_ips_icon() -> Element(Msg) {
  svg.svg(
    [
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "none"),
      attribute("stroke", "currentColor"),
      attribute("stroke-width", "2"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-linejoin", "round"),
    ],
    [
      svg.rect([
        attribute("x", "2"),
        attribute("y", "2"),
        attribute("width", "20"),
        attribute("height", "8"),
        attribute("rx", "2"),
        attribute("ry", "2"),
      ]),
      svg.rect([
        attribute("x", "2"),
        attribute("y", "14"),
        attribute("width", "20"),
        attribute("height", "8"),
        attribute("rx", "2"),
        attribute("ry", "2"),
      ]),
      svg.line([
        attribute("x1", "6"),
        attribute("y1", "6"),
        attribute("x2", "6.01"),
        attribute("y2", "6"),
      ]),
      svg.line([
        attribute("x1", "6"),
        attribute("y1", "18"),
        attribute("x2", "6.01"),
        attribute("y2", "18"),
      ]),
    ],
  )
}

fn last_activity_icon() -> Element(Msg) {
  svg.svg(
    [
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "none"),
      attribute("stroke", "currentColor"),
      attribute("stroke-width", "2"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-linejoin", "round"),
    ],
    [
      svg.circle([
        attribute("cx", "12"),
        attribute("cy", "12"),
        attribute("r", "10"),
      ]),
      svg.polyline([attribute("points", "12 6 12 12 16 14")]),
    ],
  )
}

fn search_icon() -> Element(Msg) {
  svg.svg(
    [
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "none"),
      attribute("stroke", "currentColor"),
      attribute("stroke-width", "2"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-linejoin", "round"),
    ],
    [
      svg.circle([
        attribute("cx", "11"),
        attribute("cy", "11"),
        attribute("r", "8"),
      ]),
      svg.line([
        attribute("x1", "21"),
        attribute("y1", "21"),
        attribute("x2", "16.65"),
        attribute("y2", "16.65"),
      ]),
    ],
  )
}

fn refresh_icon() -> Element(Msg) {
  svg.svg(
    [
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "none"),
      attribute("stroke", "currentColor"),
      attribute("stroke-width", "2"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-linejoin", "round"),
      style("width", "18px"),
      style("height", "18px"),
    ],
    [
      svg.polyline([attribute("points", "23 4 23 10 17 10")]),
      svg.polyline([attribute("points", "1 20 1 14 7 14")]),
      svg.path([
        attribute(
          "d",
          "M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15",
        ),
      ]),
    ],
  )
}

fn simulate_icon() -> Element(Msg) {
  svg.svg(
    [
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "none"),
      attribute("stroke", "currentColor"),
      attribute("stroke-width", "2"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-linejoin", "round"),
      style("width", "18px"),
      style("height", "18px"),
    ],
    [
      svg.path([
        attribute(
          "d",
          "M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z",
        ),
      ]),
      svg.polyline([attribute("points", "14 2 14 8 20 8")]),
      svg.line([
        attribute("x1", "12"),
        attribute("y1", "18"),
        attribute("x2", "12"),
        attribute("y2", "12"),
      ]),
      svg.line([
        attribute("x1", "9"),
        attribute("y1", "15"),
        attribute("x2", "15"),
        attribute("y2", "15"),
      ]),
    ],
  )
}

// MISC HELPERS

fn copy_icon() -> Element(Msg) {
  svg.svg(
    [
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "none"),
      attribute("stroke", "currentColor"),
      attribute("stroke-width", "2"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-linejoin", "round"),
      style("width", "14px"),
      style("height", "14px"),
    ],
    [
      svg.rect([
        attribute("x", "9"),
        attribute("y", "9"),
        attribute("width", "13"),
        attribute("height", "13"),
        attribute("rx", "2"),
        attribute("ry", "2"),
      ]),
      svg.path([
        attribute(
          "d",
          "M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1",
        ),
      ]),
    ],
  )
}

fn delete_icon() -> Element(Msg) {
  svg.svg(
    [
      attribute("viewBox", "0 0 24 24"),
      attribute("fill", "none"),
      attribute("stroke", "currentColor"),
      attribute("stroke-width", "2"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-linejoin", "round"),
      style("width", "16px"),
      style("height", "16px"),
    ],
    [
      svg.polyline([attribute("points", "3 6 5 6 21 6")]),
      svg.path([
        attribute(
          "d",
          "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2",
        ),
      ]),
      svg.line([
        attribute("x1", "10"),
        attribute("y1", "11"),
        attribute("x2", "10"),
        attribute("y2", "17"),
      ]),
      svg.line([
        attribute("x1", "14"),
        attribute("y1", "11"),
        attribute("x2", "14"),
        attribute("y2", "17"),
      ]),
    ],
  )
}

// MISC HELPERS

fn filter_client(query: String) -> fn(Client) -> Bool {
  fn(client: Client) {
    case string.is_empty(query) {
      True -> True
      False -> {
        let q = string.lowercase(query)
        string.contains(string.lowercase(client.client_id), q)
        || string.contains(client.ip, q)
        || string.contains(string.lowercase(client.ssh.user), q)
        || string.contains(string.lowercase(client.ssh.host_key), q)
      }
    }
  }
}

fn unique_list(list: List(a)) -> List(a) {
  list.fold(list, [], fn(acc, x) {
    case list.contains(acc, x) {
      True -> acc
      False -> list.append(acc, [x])
    }
  })
}

fn format_time_str(iso: String) -> String {
  let parts = string.split(iso, "T")
  let date = case list.first(parts) {
    Ok(d) -> d
    Error(_) -> ""
  }
  let time_full = case list.last(parts) {
    Ok(t) -> t
    Error(_) -> ""
  }
  let time_parts = string.split(time_full, ".")
  let time = case list.first(time_parts) {
    Ok(t) -> t
    Error(_) -> ""
  }
  let clean_time = string.replace(time, "Z", "")

  case string.is_empty(date) {
    True -> iso
    False -> date <> " " <> clean_time
  }
}

// JSON DECODERS

fn ssh_config_decoder_dash() -> decode.Decoder(SSHConfig) {
  use user <- decode.field("user", decode.string)
  use port <- decode.field("port", decode.int)
  use host_key <- decode.field("host-key", decode.string)
  decode.success(SSHConfig(user, port, host_key))
}

fn ssh_config_decoder_under() -> decode.Decoder(SSHConfig) {
  use user <- decode.field("user", decode.string)
  use port <- decode.field("port", decode.int)
  use host_key <- decode.field("host_key", decode.string)
  decode.success(SSHConfig(user, port, host_key))
}

fn ssh_config_decoder() -> decode.Decoder(SSHConfig) {
  decode.one_of(
    ssh_config_decoder_dash(),
    or: [ssh_config_decoder_under()],
  )
}

fn client_decoder() -> decode.Decoder(Client) {
  use client_id <- decode.field("client_id", decode.string)
  use ip <- decode.field("ip", decode.string)
  use ssh <- decode.field("ssh", ssh_config_decoder())
  use created_at <- decode.field("created_at", decode.string)
  decode.success(Client(client_id, ip, ssh, created_at))
}

fn clients_list_decoder() -> decode.Decoder(List(Client)) {
  decode.list(client_decoder())
}

// PROGRAM ENTRY

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
