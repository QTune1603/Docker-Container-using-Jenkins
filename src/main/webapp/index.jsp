<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <!DOCTYPE html>
    <html lang="en">

    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>DevOps Lab - Project 05</title>
        <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
        <style>
            :root {
                --bg-color: #0b0f19;
                --card-bg: rgba(255, 255, 255, 0.03);
                --border-color: rgba(255, 255, 255, 0.08);
                --primary-gradient: linear-gradient(135deg, #00f2fe 0%, #4facfe 100%);
                --accent-gradient: linear-gradient(135deg, #ff0844 0%, #ffb199 100%);
                --glow-color: rgba(0, 242, 254, 0.15);
                --text-main: #f8fafc;
                --text-muted: #94a3b8;
            }

            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: 'Outfit', sans-serif;
                background-color: var(--bg-color);
                color: var(--text-main);
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
                position: relative;
                overflow: hidden;
                background-image:
                    radial-gradient(circle at 10% 20%, rgba(0, 242, 254, 0.05) 0%, transparent 40%),
                    radial-gradient(circle at 90% 80%, rgba(255, 8, 68, 0.05) 0%, transparent 40%);
            }

            .container {
                max-width: 800px;
                width: 90%;
                text-align: center;
                padding: 2rem;
                z-index: 1;
            }

            .card {
                background: var(--card-bg);
                border: 1px solid var(--border-color);
                border-radius: 24px;
                padding: 3rem 2rem;
                backdrop-filter: blur(16px);
                box-shadow: 0 20px 50px rgba(0, 0, 0, 0.3), 0 0 40px var(--glow-color);
                transition: transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275), box-shadow 0.4s ease;
                position: relative;
                overflow: hidden;
            }

            .card::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 4px;
                background: var(--primary-gradient);
            }

            .card:hover {
                transform: translateY(-8px);
                box-shadow: 0 30px 60px rgba(0, 0, 0, 0.4), 0 0 50px rgba(0, 242, 254, 0.25);
            }

            .badge {
                display: inline-block;
                padding: 0.5rem 1rem;
                background: rgba(0, 242, 254, 0.1);
                border: 1px solid rgba(0, 242, 254, 0.2);
                color: #00f2fe;
                border-radius: 50px;
                font-size: 0.85rem;
                font-weight: 600;
                margin-bottom: 1.5rem;
                text-transform: uppercase;
                letter-spacing: 0.05em;
                animation: pulse 2s infinite alternate;
            }

            h1 {
                font-size: 2.8rem;
                font-weight: 800;
                margin-bottom: 1rem;
                background: var(--primary-gradient);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                letter-spacing: -0.02em;
            }

            p {
                font-size: 1.1rem;
                color: var(--text-muted);
                line-height: 1.6;
                margin-bottom: 2.5rem;
            }

            .grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 1.5rem;
                margin-bottom: 2.5rem;
            }

            .tech-item {
                background: rgba(255, 255, 255, 0.01);
                border: 1px solid var(--border-color);
                border-radius: 16px;
                padding: 1.5rem;
                transition: all 0.3s ease;
            }

            .tech-item:hover {
                background: rgba(255, 255, 255, 0.04);
                border-color: rgba(0, 242, 254, 0.3);
                transform: scale(1.03);
            }

            .tech-icon {
                font-size: 1.8rem;
                margin-bottom: 0.75rem;
            }

            .tech-name {
                font-weight: 600;
                color: var(--text-main);
                margin-bottom: 0.25rem;
            }

            .tech-desc {
                font-size: 0.85rem;
                color: var(--text-muted);
            }

            .footer {
                font-size: 0.9rem;
                color: var(--text-muted);
                border-top: 1px solid var(--border-color);
                padding-top: 1.5rem;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }

            .status-dot {
                width: 8px;
                height: 8px;
                background-color: #10b981;
                border-radius: 50%;
                display: inline-block;
                margin-right: 6px;
                box-shadow: 0 0 8px #10b981;
            }

            .status-container {
                display: flex;
                align-items: center;
                font-weight: 500;
            }

            @keyframes pulse {
                0% {
                    box-shadow: 0 0 0 0 rgba(0, 242, 254, 0.4);
                }

                70% {
                    box-shadow: 0 0 0 10px rgba(0, 242, 254, 0);
                }

                100% {
                    box-shadow: 0 0 0 0 rgba(0, 242, 254, 0);
                }
            }

            @media (max-width: 600px) {
                h1 {
                    font-size: 2.2rem;
                }

                .grid {
                    grid-template-columns: 1fr;
                }
            }
        </style>
    </head>

    <body>
        <div class="container">
            <div class="card">
                <span class="badge">Successful Deployment</span>
                <h1>Tran Quang Tung's Awesome CI/CD Pipeline!</h1>
                <h1>Jenkins & Docker Lab</h1>
                <p>Your Java Web Application has been successfully compiled, packaged, containerized, and deployed by
                    the Jenkins CI/CD pipeline onto a Docker container running Tomcat.</p>

                <div class="grid">
                    <div class="tech-item">
                        <div class="tech-icon">☕</div>
                        <div class="tech-name">Maven & Java</div>
                        <div class="tech-desc">Build & Package</div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-icon">🐳</div>
                        <div class="tech-name">Docker Host</div>
                        <div class="tech-desc">Tomcat Containerization</div>
                    </div>
                    <div class="tech-item">
                        <div class="tech-icon">⚙️</div>
                        <div class="tech-name">Jenkins</div>
                        <div class="tech-desc">Automated CI/CD</div>
                    </div>
                </div>

                <div class="footer">
                    <div class="status-container">
                        <span class="status-dot"></span>
                        <span>Application Active</span>
                    </div>
                    <div>Lab Project</div>
                </div>
            </div>
        </div>
    </body>

    </html>