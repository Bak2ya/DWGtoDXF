using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("DWG2DXF")]
[assembly: AssemblyDescription("DWG2DXF converter launcher")]
[assembly: AssemblyCompany("HJU")]
[assembly: AssemblyProduct("DWG2DXF")]
[assembly: AssemblyVersion("1.3.0.0")]
[assembly: AssemblyFileVersion("1.3.0.0")]

internal static class Program
{
    private const string AppVersion = "1.3.0";

    private sealed class ResourceItem
    {
        public string ResourceName;
        public string RelativePath;

        public ResourceItem(string resourceName, string relativePath)
        {
            ResourceName = resourceName;
            RelativePath = relativePath;
        }
    }

    private static readonly ResourceItem[] Payload = new ResourceItem[]
    {
        new ResourceItem("DWG2DXF.payload.DWG2DXF.ps1", "DWG2DXF.ps1"),
        new ResourceItem("HJU.payload.resources.wqy-unicode.lff", Path.Combine("resources", "wqy-unicode.lff")),
        new ResourceItem("HJU.payload.resources.app.ico", Path.Combine("resources", "app.ico")),
        new ResourceItem("HJU.payload.resources.app_logo.png", Path.Combine("resources", "app_logo.png")),
        new ResourceItem("HJU.payload.lib.ACadSharp.dll", Path.Combine("lib", "ACadSharp.dll")),
        new ResourceItem("HJU.payload.lib.System.Memory.dll", Path.Combine("lib", "System.Memory.dll")),
        new ResourceItem("HJU.payload.lib.System.Buffers.dll", Path.Combine("lib", "System.Buffers.dll")),
        new ResourceItem("HJU.payload.lib.System.Numerics.Vectors.dll", Path.Combine("lib", "System.Numerics.Vectors.dll")),
        new ResourceItem("HJU.payload.lib.System.Runtime.CompilerServices.Unsafe.dll", Path.Combine("lib", "System.Runtime.CompilerServices.Unsafe.dll")),
        new ResourceItem("HJU.payload.licenses.Apache-2.0.txt", Path.Combine("licenses", "Apache-2.0.txt")),
        new ResourceItem("HJU.payload.licenses.WQY_FONT_NOTICE.txt", Path.Combine("licenses", "WQY_FONT_NOTICE.txt")),
        new ResourceItem("HJU.payload.THIRD_PARTY_NOTICES.txt", "THIRD_PARTY_NOTICES.txt")
    };

    [STAThread]
    private static int Main()
    {
        try
        {
            string baseDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "DWG2DXF",
                AppVersion);

            Directory.CreateDirectory(baseDir);
            ExtractPayload(baseDir);

            string scriptPath = Path.Combine(baseDir, "DWG2DXF.ps1");
            if (!File.Exists(scriptPath))
                throw new FileNotFoundException(T("payload"), scriptPath);

            string powershell = FindPowerShell();
            if (string.IsNullOrEmpty(powershell))
                throw new FileNotFoundException(T("powershell"));

            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = powershell;
            psi.Arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File \"" + scriptPath + "\"";
            psi.WorkingDirectory = baseDir;
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;
            psi.WindowStyle = ProcessWindowStyle.Hidden;

            Process process = Process.Start(psi);
            if (process == null)
                throw new InvalidOperationException(T("launch"));

            return 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                T("start") + "\r\n\r\n" + ex.Message + "\r\n\r\n" + T("retry"),
                "DWG2DXF",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 1;
        }
    }

    private static string Lang()
    {
        string name = CultureInfo.CurrentUICulture.Name.ToLowerInvariant();
        if (name.StartsWith("ko")) return "ko";
        if (name.StartsWith("ja")) return "ja";
        if (name.StartsWith("es")) return "es";
        return "en";
    }

    private static string T(string key)
    {
        string l = Lang();
        if (l == "ko")
        {
            if (key == "payload") return "내장 실행 파일을 준비하지 못했습니다.";
            if (key == "powershell") return "Windows PowerShell 5.1을 찾지 못했습니다.";
            if (key == "launch") return "프로그램 실행에 실패했습니다.";
            if (key == "start") return "DWG2DXF를 시작하지 못했습니다.";
            if (key == "retry") return "문제가 계속되면 프로그램을 다시 빌드하거나 배포 파일을 다시 복사해 주세요.";
            if (key == "resource") return "내장 리소스를 찾지 못했습니다: ";
        }
        else if (l == "ja")
        {
            if (key == "payload") return "内蔵実行ファイルを準備できませんでした。";
            if (key == "powershell") return "Windows PowerShell 5.1 が見つかりません。";
            if (key == "launch") return "プログラムを起動できませんでした。";
            if (key == "start") return "DWG2DXFを開始できませんでした。";
            if (key == "retry") return "問題が続く場合は、プログラムを再ビルドするか配布ファイルを再コピーしてください。";
            if (key == "resource") return "内蔵リソースが見つかりません: ";
        }
        else if (l == "es")
        {
            if (key == "payload") return "No se pudo preparar el archivo de ejecución incluido.";
            if (key == "powershell") return "No se encontró Windows PowerShell 5.1.";
            if (key == "launch") return "No se pudo iniciar el programa.";
            if (key == "start") return "No se pudo iniciar DWG2DXF.";
            if (key == "retry") return "Si el problema continúa, vuelve a compilar el programa o copia de nuevo el archivo de distribución.";
            if (key == "resource") return "No se encontró el recurso incluido: ";
        }

        if (key == "payload") return "The embedded application file could not be prepared.";
        if (key == "powershell") return "Windows PowerShell 5.1 could not be found.";
        if (key == "launch") return "The application could not be started.";
        if (key == "start") return "DWG2DXF could not be started.";
        if (key == "retry") return "If the problem continues, rebuild the application or copy the distribution file again.";
        if (key == "resource") return "Embedded resource not found: ";
        return key;
    }

    private static void ExtractPayload(string baseDir)
    {
        Assembly asm = Assembly.GetExecutingAssembly();

        foreach (ResourceItem item in Payload)
        {
            string outputPath = Path.Combine(baseDir, item.RelativePath);
            string outputDir = Path.GetDirectoryName(outputPath);
            if (!string.IsNullOrEmpty(outputDir))
                Directory.CreateDirectory(outputDir);

            using (Stream input = asm.GetManifestResourceStream(item.ResourceName))
            {
                if (input == null)
                    throw new InvalidOperationException(T("resource") + item.ResourceName);

                using (FileStream output = new FileStream(outputPath, FileMode.Create, FileAccess.Write, FileShare.Read))
                {
                    input.CopyTo(output);
                }
            }
        }
    }

    private static string FindPowerShell()
    {
        string systemDir = Environment.GetFolderPath(Environment.SpecialFolder.System);
        string candidate = Path.Combine(systemDir, "WindowsPowerShell", "v1.0", "powershell.exe");
        if (File.Exists(candidate))
            return candidate;

        string windowsDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
        candidate = Path.Combine(windowsDir, "System32", "WindowsPowerShell", "v1.0", "powershell.exe");
        if (File.Exists(candidate))
            return candidate;

        return "powershell.exe";
    }
}
