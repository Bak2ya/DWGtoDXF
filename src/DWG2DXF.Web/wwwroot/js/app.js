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

    getDarkMode() {
        return localStorage.getItem('dwg2dxf.darkMode') === 'true';
    },

    setDarkMode(value) {
        localStorage.setItem('dwg2dxf.darkMode', value ? 'true' : 'false');
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
