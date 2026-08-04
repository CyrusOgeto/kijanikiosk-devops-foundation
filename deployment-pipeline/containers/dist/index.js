// ============================================================
// Developed by: Cyrus Ogeto
// Project: KijaniKiosk Payments API
// Purpose: Simple HTTP server that responds to /health requests
// ============================================================

const http = require('http');

const server = http.createServer((req, res) => {
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'healthy',
            version: '1.0.0',
            timestamp: new Date().toISOString()
        }));
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`KijaniKiosk Payments API running on port ${PORT}`);
});
