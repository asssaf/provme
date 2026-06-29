export function fetch_json(url, method, body, on_success, on_error) {
    const options = { method };
    if (body) {
        options.headers = { 'Content-Type': 'application/json' };
        options.body = body;
    }
    fetch(url, options)
        .then(res => {
            if (!res.ok) {
                return res.json().then(
                    data => { throw new Error(data.error || 'Failed request'); },
                    () => { throw new Error('Failed request'); }
                );
            }
            return res.json();
        })
        .then(data => on_success(data))
        .catch(err => on_error(err.message));
}

export function copy_to_clipboard(text, on_success) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text)
            .then(() => on_success())
            .catch(err => {
                console.warn("navigator.clipboard failed, falling back: ", err);
                fallback_copy(text, on_success);
            });
    } else {
        fallback_copy(text, on_success);
    }
}

function fallback_copy(text, on_success) {
    try {
        const textArea = document.createElement("textarea");
        textArea.value = text;
        textArea.style.top = "0";
        textArea.style.left = "0";
        textArea.style.position = "fixed";
        textArea.style.opacity = "0";
        
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        
        const successful = document.execCommand('copy');
        document.body.removeChild(textArea);
        
        if (successful) {
            on_success();
        }
    } catch (err) {
        console.error("Fallback copy threw error: ", err);
    }
}

export function start_timer(ms, callback) {
    setInterval(callback, ms);
}

function generate_mock_payload() {
    const client_id = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });

    const subnets = [192, 172, 10];
    let ip = '';
    const type = subnets[Math.floor(Math.random() * subnets.length)];
    if (type === 192) {
        ip = `192.168.${Math.floor(Math.random() * 254) + 1}.${Math.floor(Math.random() * 254) + 1}`;
    } else if (type === 172) {
        ip = `172.16.${Math.floor(Math.random() * 15) + 16}.${Math.floor(Math.random() * 254) + 1}`;
    } else {
        ip = `10.${Math.floor(Math.random() * 254)}.${Math.floor(Math.random() * 254)}.${Math.floor(Math.random() * 254) + 1}`;
    }

    const users = ['ubuntu', 'admin', 'root', 'ec2-user', 'debian', 'alpine'];
    const ports = [22, 22, 22, 2222, 8022];
    const user = users[Math.floor(Math.random() * users.length)];
    const port = ports[Math.floor(Math.random() * ports.length)];
    
    const keyTypes = ['ssh-ed25519', 'ssh-rsa', 'ecdsa-sha2-nistp256'];
    const keyType = keyTypes[Math.floor(Math.random() * keyTypes.length)];
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let keyBody = '';
    for(let i=0; i<60; i++) {
        keyBody += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    const hostKey = `${keyType} AAAAC3NzaC1lZDI1NTE5${keyBody}...`;

    return {
        client_id,
        ip,
        ssh: {
            user,
            port,
            'host-key': hostKey
        }
    };
}

export function simulate_registration(on_success, on_error) {
    const payload = generate_mock_payload();
    fetch_json('/v1/register', 'POST', JSON.stringify(payload), on_success, on_error);
}

export function run_after(ms, callback) {
    setTimeout(callback, ms);
}

