window.dwg2dxf = {
    async downloadStream(fileName, streamReference) {
        const arrayBuffer = await streamReference.arrayBuffer();
        const blob = new Blob([arrayBuffer]);
        const url = URL.createObjectURL(blob);
        const anchor = document.createElement('a');

        anchor.href = url;
        anchor.download = fileName;

        document.body.appendChild(anchor);
        anchor.click();
        anchor.remove();

        URL.revokeObjectURL(url);
    },

    getThemeMode() {
        const saved = localStorage.getItem('dwg2dxf.themeMode');
        if (saved === 'system' || saved === 'light' || saved === 'dark') return saved;
        const legacy = localStorage.getItem('dwg2dxf.darkMode');
        return legacy === 'true' ? 'dark' : legacy === 'false' ? 'light' : 'system';
    },

    setThemeMode(value) {
        const mode = ['system', 'light', 'dark'].includes(value) ? value : 'system';
        localStorage.setItem('dwg2dxf.themeMode', mode);
    },

    async openInPieniPlan(streamReference, details) {
        // Open synchronously during the click handler, before streaming bytes or opening IDB.
        const target = window.open('about:blank', '_blank');
        if (!target) throw new Error('POPUP_BLOCKED');
        try {
            target.opener = null;
            if (!window.isSecureContext || !crypto.randomUUID) throw new Error('SECURE_CONTEXT_REQUIRED');
            if (!window.indexedDB) throw new Error('IDB_UNAVAILABLE');
            const convertedFileName = details?.convertedFileName;
            const originalFileName = details?.originalFileName;
            if (typeof convertedFileName !== 'string' || convertedFileName.length > 240 ||
                !/\.dxf$/i.test(convertedFileName) ||
                typeof originalFileName !== 'string' || !originalFileName.length || originalFileName.length > 240) {
                throw new Error('INVALID_FILENAME');
            }
            const data = await streamReference.arrayBuffer();
            if (!(data instanceof ArrayBuffer) || data.byteLength < 8 || data.byteLength > 128 * 1024 * 1024) {
                throw new Error('INVALID_DXF_BYTES');
            }
            const id = crypto.randomUUID();
            const createdAt = Date.now();
            const diffs = details?.validation?.differences;
            const validation = {
                needsReview: details?.validation?.needsReview === true,
                differences: Array.isArray(diffs)
                    ? diffs.slice(0, 50).map(x => String(x).slice(0, 300))
                    : []
            };
            const record = {
                protocol: 'dwg2dxf-pieniplan', version: 1, id,
                sourceApp: 'DWG2DXF', originalFileName, convertedFileName,
                dxfData: data, validation,
                createdAt, expiresAt: createdAt + 1800000
            };
            const db = await new Promise((resolve, reject) => {
                const request = indexedDB.open('pieniplan-dxf-handoff', 1);
                request.onupgradeneeded = () => {
                    if (!request.result.objectStoreNames.contains('transfers')) {
                        request.result.createObjectStore('transfers', { keyPath: 'id' });
                    }
                };
                request.onsuccess = () => resolve(request.result);
                request.onerror = () => reject(request.error || new Error('IDB_OPEN_FAILED'));
                request.onblocked = () => reject(new Error('IDB_BLOCKED'));
            });
            try {
                await new Promise((resolve, reject) => {
                    const transaction = db.transaction('transfers', 'readwrite');
                    transaction.objectStore('transfers').put(record);
                    transaction.oncomplete = () => resolve();
                    transaction.onerror = () => reject(transaction.error || new Error('IDB_WRITE_FAILED'));
                    transaction.onabort = () => reject(transaction.error || new Error('IDB_ABORTED'));
                });
            } finally {
                db.close();
            }
            if (target.closed) throw new Error('TAB_CLOSED');
            target.location.replace('https://bak2ya.github.io/PieniPlan/?dxfHandoff=' + encodeURIComponent(id));
            return id;
        } catch (error) {
            try { target.close(); } catch (_) {}
            throw error;
        }
    },

    getLanguage() {
        const saved = localStorage.getItem('dwg2dxf.language');
        if (saved) return this.normalizeLanguage(saved);

        const browserLanguage =
            (navigator.languages && navigator.languages.length > 0
                ? navigator.languages[0]
                : navigator.language) || 'en';

        return this.normalizeLanguage(browserLanguage);
    },

    setLanguage(value, description) {
        const normalized = this.normalizeLanguage(value);

        localStorage.setItem('dwg2dxf.language', normalized);
        document.documentElement.lang = normalized;

        const meta = document.querySelector('meta[name="description"]');
        if (meta && description) meta.setAttribute('content', description);
    },

    normalizeLanguage(value) {
        const code = String(value || 'en').toLowerCase();

        if (code.startsWith('ko')) return 'ko';
        if (code.startsWith('ja')) return 'ja';
        if (code.startsWith('es')) return 'es';

        return 'en';
    }
};
