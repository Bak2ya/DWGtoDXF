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
    }
};
