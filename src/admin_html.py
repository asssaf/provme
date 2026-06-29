ADMIN_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Provme Admin Management</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-main: #0b0f19;
            --bg-card: rgba(17, 24, 39, 0.7);
            --bg-card-hover: rgba(26, 36, 57, 0.85);
            --border-color: rgba(255, 255, 255, 0.08);
            --text-primary: #f3f4f6;
            --text-secondary: #9ca3af;
            --text-muted: #6b7280;
            --primary: #8b5cf6;
            --primary-hover: #7c3aed;
            --primary-glow: rgba(139, 92, 246, 0.15);
            --cyan: #06b6d4;
            --emerald: #10b981;
            --rose: #f43f5e;
            --amber: #f59e0b;
            --font-display: 'Plus Jakarta Sans', sans-serif;
            --font-sans: 'Outfit', sans-serif;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            background-color: var(--bg-main);
            background-image: 
                radial-gradient(at 0% 0%, rgba(139, 92, 246, 0.08) 0px, transparent 50%),
                radial-gradient(at 100% 100%, rgba(6, 182, 212, 0.08) 0px, transparent 50%);
            background-attachment: fixed;
            color: var(--text-primary);
            font-family: var(--font-sans);
            min-height: 100vh;
            padding: 2rem 1.5rem;
            line-height: 1.5;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        /* Header Styling */
        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2.5rem;
            padding-bottom: 1.5rem;
            border-bottom: 1px solid var(--border-color);
        }

        .logo-section {
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }

        .logo-icon {
            background: linear-gradient(135deg, var(--primary), var(--cyan));
            width: 40px;
            height: 40px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 0 20px var(--primary-glow);
        }

        .logo-icon svg {
            width: 22px;
            height: 22px;
            fill: white;
        }

        .title-group h1 {
            font-family: var(--font-display);
            font-size: 1.5rem;
            font-weight: 700;
            background: linear-gradient(to right, #ffffff, #d1d5db);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            letter-spacing: -0.02em;
        }

        .title-group p {
            font-size: 0.85rem;
            color: var(--text-secondary);
        }

        .status-badge {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            background: rgba(16, 185, 129, 0.08);
            border: 1px solid rgba(16, 185, 129, 0.2);
            padding: 0.4rem 0.8rem;
            border-radius: 9999px;
            font-size: 0.8rem;
            font-weight: 500;
            color: var(--emerald);
        }

        .status-dot {
            width: 8px;
            height: 8px;
            background-color: var(--emerald);
            border-radius: 50%;
            display: inline-block;
            box-shadow: 0 0 8px var(--emerald);
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { transform: scale(0.9); opacity: 0.6; }
            50% { transform: scale(1.15); opacity: 1; box-shadow: 0 0 12px var(--emerald); }
            100% { transform: scale(0.9); opacity: 0.6; }
        }

        /* Stats Section */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2.5rem;
        }

        .stat-card {
            background: var(--bg-card);
            backdrop-filter: blur(12px);
            border: 1px solid var(--border-color);
            padding: 1.5rem;
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
        }

        .stat-card:hover {
            transform: translateY(-4px);
            border-color: rgba(255, 255, 255, 0.15);
            background: var(--bg-card-hover);
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3);
        }

        .stat-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 2px;
            background: linear-gradient(90deg, transparent, var(--card-accent, var(--primary)), transparent);
            opacity: 0;
            transition: opacity 0.3s ease;
        }

        .stat-card:hover::before {
            opacity: 1;
        }

        .stat-info h3 {
            font-size: 0.85rem;
            font-weight: 500;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 0.5rem;
        }

        .stat-value {
            font-family: var(--font-display);
            font-size: 2rem;
            font-weight: 700;
            color: white;
            line-height: 1.1;
        }

        .stat-desc {
            font-size: 0.75rem;
            color: var(--text-muted);
            margin-top: 0.25rem;
        }

        .stat-icon-wrapper {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.05);
            color: var(--card-accent, var(--primary));
        }

        .stat-icon-wrapper svg {
            width: 24px;
            height: 24px;
        }

        /* Controls Section */
        .controls-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 1rem;
            margin-bottom: 1.5rem;
        }

        .search-wrapper {
            position: relative;
            flex-grow: 1;
            max-width: 400px;
            min-width: 260px;
        }

        .search-input {
            width: 100%;
            background: var(--bg-card);
            border: 1px solid var(--border-color);
            color: white;
            font-family: var(--font-sans);
            font-size: 0.9rem;
            padding: 0.75rem 1rem 0.75rem 2.5rem;
            border-radius: 12px;
            outline: none;
            transition: all 0.2s ease;
        }

        .search-input:focus {
            border-color: var(--primary);
            box-shadow: 0 0 10px var(--primary-glow);
            background: var(--bg-card-hover);
        }

        .search-icon {
            position: absolute;
            left: 0.85rem;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-muted);
            pointer-events: none;
            display: flex;
            align-items: center;
        }

        .search-icon svg {
            width: 18px;
            height: 18px;
        }

        .actions-group {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            flex-wrap: wrap;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            font-family: var(--font-sans);
            font-size: 0.875rem;
            font-weight: 500;
            padding: 0.75rem 1.25rem;
            border-radius: 12px;
            border: 1px solid transparent;
            cursor: pointer;
            transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
            outline: none;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--primary), #6366f1);
            color: white;
            box-shadow: 0 4px 15px var(--primary-glow);
        }

        .btn-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 6px 20px rgba(139, 92, 246, 0.25);
            background: linear-gradient(135deg, var(--primary-hover), #4f46e5);
        }

        .btn-primary:active {
            transform: translateY(1px);
        }

        .btn-secondary {
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid var(--border-color);
            color: var(--text-primary);
        }

        .btn-secondary:hover {
            background: rgba(255, 255, 255, 0.08);
            border-color: rgba(255, 255, 255, 0.15);
            color: white;
        }

        .btn-danger-link {
            background: transparent;
            border: none;
            color: var(--text-muted);
            padding: 0.25rem;
            border-radius: 6px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s ease;
        }

        .btn-danger-link:hover {
            color: var(--rose);
            background: rgba(244, 63, 94, 0.1);
        }

        .btn-icon-only {
            padding: 0.75rem;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        /* Refresh icon rotate animation */
        .rotating svg {
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }

        .refresh-toggle-container {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid var(--border-color);
            padding: 0.5rem 0.85rem;
            border-radius: 12px;
            font-size: 0.8rem;
            color: var(--text-secondary);
        }

        /* Switch toggle styling */
        .switch {
            position: relative;
            display: inline-block;
            width: 34px;
            height: 20px;
        }

        .switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }

        .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: rgba(255, 255, 255, 0.1);
            transition: .3s;
            border-radius: 34px;
            border: 1px solid var(--border-color);
        }

        .slider:before {
            position: absolute;
            content: "";
            height: 12px;
            width: 12px;
            left: 3px;
            bottom: 3px;
            background-color: var(--text-secondary);
            transition: .3s;
            border-radius: 50%;
        }

        input:checked + .slider {
            background-color: var(--primary-glow);
            border-color: var(--primary);
        }

        input:checked + .slider:before {
            transform: translateX(14px);
            background-color: var(--primary);
        }

        /* Table Styling */
        .table-container {
            background: var(--bg-card);
            backdrop-filter: blur(12px);
            border: 1px solid var(--border-color);
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 4px 30px rgba(0, 0, 0, 0.15);
            margin-bottom: 2rem;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            font-size: 0.9rem;
        }

        thead {
            background: rgba(255, 255, 255, 0.02);
            border-bottom: 1px solid var(--border-color);
            font-family: var(--font-display);
        }

        th {
            color: var(--text-secondary);
            font-weight: 600;
            padding: 1rem 1.5rem;
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        tbody tr {
            border-bottom: 1px solid rgba(255, 255, 255, 0.04);
            transition: background-color 0.2s ease;
        }

        tbody tr:last-child {
            border-bottom: none;
        }

        tbody tr:hover {
            background-color: rgba(255, 255, 255, 0.015);
        }

        td {
            padding: 1rem 1.5rem;
            color: var(--text-primary);
            vertical-align: middle;
        }

        .td-client-id {
            font-family: monospace;
            font-size: 0.85rem;
            color: var(--text-primary);
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .client-id-text {
            color: var(--cyan);
            font-weight: 500;
        }

        .copy-btn {
            background: transparent;
            border: none;
            color: var(--text-muted);
            cursor: pointer;
            padding: 0.2rem;
            border-radius: 4px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            transition: all 0.15s ease;
        }

        .copy-btn:hover {
            color: white;
            background: rgba(255, 255, 255, 0.06);
        }

        .copy-btn.success {
            color: var(--emerald);
        }

        .td-ip {
            font-weight: 600;
            font-family: monospace;
            color: var(--text-primary);
        }

        .ssh-badge-user {
            background: rgba(139, 92, 246, 0.1);
            border: 1px solid rgba(139, 92, 246, 0.2);
            color: #c084fc;
            padding: 0.15rem 0.5rem;
            border-radius: 6px;
            font-family: monospace;
            font-size: 0.8rem;
            font-weight: 500;
        }

        .ssh-badge-port {
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid var(--border-color);
            color: var(--text-secondary);
            padding: 0.15rem 0.4rem;
            border-radius: 6px;
            font-family: monospace;
            font-size: 0.8rem;
        }

        .key-preview {
            max-width: 150px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            font-family: monospace;
            font-size: 0.75rem;
            color: var(--text-muted);
            display: inline-block;
            vertical-align: middle;
        }

        .key-action-btn {
            background: transparent;
            border: none;
            color: var(--primary);
            font-family: var(--font-sans);
            font-size: 0.75rem;
            font-weight: 500;
            cursor: pointer;
            padding: 0.15rem 0.35rem;
            border-radius: 4px;
            transition: all 0.2s ease;
        }

        .key-action-btn:hover {
            text-decoration: underline;
            color: #a78bfa;
        }

        .time-text {
            font-size: 0.85rem;
            color: var(--text-secondary);
        }

        /* Empty State */
        .empty-state {
            padding: 4rem 2rem;
            text-align: center;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }

        .empty-icon {
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid var(--border-color);
            width: 64px;
            height: 64px;
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 1.5rem;
            color: var(--text-muted);
        }

        .empty-icon svg {
            width: 32px;
            height: 32px;
        }

        .empty-state h3 {
            font-family: var(--font-display);
            font-size: 1.15rem;
            font-weight: 600;
            color: white;
            margin-bottom: 0.5rem;
        }

        .empty-state p {
            font-size: 0.875rem;
            color: var(--text-secondary);
            max-width: 320px;
            margin-bottom: 1.5rem;
        }

        /* Modal Overlay */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(3, 7, 18, 0.8);
            backdrop-filter: blur(8px);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.25s ease;
        }

        .modal-overlay.open {
            opacity: 1;
            pointer-events: auto;
        }

        .modal {
            background: #111827;
            border: 1px solid var(--border-color);
            width: 100%;
            max-width: 550px;
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
            transform: scale(0.95);
            transition: transform 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
        }

        .modal-overlay.open .modal {
            transform: scale(1);
        }

        .modal-header {
            padding: 1.25rem 1.5rem;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .modal-header h3 {
            font-family: var(--font-display);
            font-size: 1.1rem;
            font-weight: 600;
            color: white;
        }

        .modal-close {
            background: transparent;
            border: none;
            color: var(--text-muted);
            cursor: pointer;
            border-radius: 6px;
            padding: 0.25rem;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s ease;
        }

        .modal-close:hover {
            color: white;
            background: rgba(255, 255, 255, 0.05);
        }

        .modal-close svg {
            width: 20px;
            height: 20px;
        }

        .modal-body {
            padding: 1.5rem;
        }

        .key-textarea-wrapper {
            position: relative;
            background: rgba(0, 0, 0, 0.25);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 1rem;
            margin-bottom: 1rem;
        }

        .key-text-box {
            font-family: monospace;
            font-size: 0.8rem;
            color: var(--cyan);
            word-break: break-all;
            white-space: pre-wrap;
            max-height: 200px;
            overflow-y: auto;
            user-select: all;
        }

        .modal-footer {
            padding: 1rem 1.5rem;
            background: rgba(0, 0, 0, 0.1);
            border-top: 1px solid var(--border-color);
            display: flex;
            justify-content: flex-end;
            gap: 0.75rem;
        }

        /* Toast Notifications */
        .toast-container {
            position: fixed;
            bottom: 2rem;
            right: 2rem;
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            z-index: 2000;
            pointer-events: none;
        }

        .toast {
            background: rgba(17, 24, 39, 0.95);
            border: 1px solid var(--border-color);
            padding: 1rem 1.25rem;
            border-radius: 12px;
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.3);
            display: flex;
            align-items: center;
            gap: 0.75rem;
            min-width: 280px;
            max-width: 400px;
            transform: translateY(20px);
            opacity: 0;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            pointer-events: auto;
        }

        .toast.show {
            transform: translateY(0);
            opacity: 1;
        }

        .toast-icon {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 24px;
            height: 24px;
            border-radius: 50%;
        }

        .toast-success .toast-icon {
            background: rgba(16, 185, 129, 0.1);
            color: var(--emerald);
        }

        .toast-error .toast-icon {
            background: rgba(244, 63, 94, 0.1);
            color: var(--rose);
        }

        .toast-info .toast-icon {
            background: rgba(6, 182, 212, 0.1);
            color: var(--cyan);
        }

        .toast-message {
            font-size: 0.85rem;
            color: white;
            font-weight: 500;
        }

        /* Responsive adjustments */
        @media (max-width: 768px) {
            body {
                padding: 1rem 1rem;
            }
            header {
                flex-direction: column;
                align-items: flex-start;
                gap: 1rem;
                margin-bottom: 1.5rem;
            }
            .status-badge {
                align-self: flex-start;
            }
            .controls-row {
                flex-direction: column;
                align-items: stretch;
            }
            .search-wrapper {
                max-width: 100%;
            }
            .actions-group {
                justify-content: space-between;
            }
            th, td {
                padding: 0.75rem 1rem;
            }
        }
    </style>
</head>
<body>
    <div id="app"></div>

    <script type="module">
        import { main } from "/static/frontend.js";
        main();
    </script>
</body>
</html>
"""
