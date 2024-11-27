<?php
ob_start();
include './cfg.php';
ini_set('memory_limit', '256M');
$subscription_file = '/etc/neko/config/subscription.txt'; 
$download_path = '/etc/neko/config/'; 
$php_script_path = '/www/nekobox/personal.php'; 
$sh_script_path = '/etc/neko/update_config.sh'; 
$log_file = '/var/log/neko_update.log'; 

function logMessage($message) {
    global $log_file;
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($log_file, "[$timestamp] $message\n", FILE_APPEND);
}

function saveSubscriptionUrlToFile($url, $file) {
    $success = file_put_contents($file, $url) !== false;
    logMessage($success ? "Subscription link has been saved to $file" : "Failed to save subscription link to $file");
    return $success;
}

function transformContent($content) {
    $new_config_start = "redir-port: 7892
port: 7890
socks-port: 7891
mixed-port: 7893
mode: rule
log-level: info
allow-lan: true
unified-delay: true
external-controller: 0.0.0.0:9090
secret: Akun
bind-address: 0.0.0.0
external-ui: ui
tproxy-port: 7895
tcp-concurrent: true	
enable-process: true
find-process-mode: always
ipv6: true
experimental:
  ignore-resolve-fail: true
  sniff-tls-sni: true
  tracing: true
hosts:
  \"localhost\": 127.0.0.1
profile:
  store-selected: true
  store-fake-ip: true
sniffer:
  enable: true
  sniff:
    http: { ports: [1-442, 444-8442, 8444-65535], override-destination: true }
    tls: { ports: [1-79, 81-8079, 8081-65535], override-destination: true }
  force-domain:
      - \"+.v2ex.com\"
      - www.google.com
      - google.com
  skip-domain:
      - Mijia Cloud
      - dlg.io.mi.com
  sniffing:
    - tls
    - http
  port-whitelist:
    - \"80\"
    - \"443\"
tun:
  enable: true
  prefer-h3: true
  listen: 0.0.0.0:53
  stack: gvisor
  dns-hijack:
     - \"any:53\"
     - \"tcp://any:53\"
  auto-redir: true
  auto-route: true
  auto-detect-interface: true
dns:
  enable: true
  ipv6: true
  default-nameserver:
    - '1.1.1.1'
    - '8.8.8.8'
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter:
    - 'stun.*.*'
    - 'stun.*.*.*'
    - '+.stun.*.*'
    - '+.stun.*.*.*'
    - '+.stun.*.*.*.*'
    - '+.stun.*.*.*.*.*'
    - '*.lan'
    - '+.msftncsi.com'
    - msftconnecttest.com
    - 'time?.*.com'
    - 'time.*.com'
    - 'time.*.gov'
    - 'time.*.apple.com'
    - time-ios.apple.com
    - 'time1.*.com'
    - 'time2.*.com'
    - 'time3.*.com'
    - 'time4.*.com'
    - 'time5.*.com'
    - 'time6.*.com'
    - 'time7.*.com'
    - 'ntp?.*.com'
    - 'ntp.*.com'
    - 'ntp1.*.com'
    - 'ntp2.*.com'
    - 'ntp3.*.com'
    - 'ntp4.*.com'
    - 'ntp5.*.com'
    - 'ntp6.*.com'
    - 'ntp7.*.com'
    - '+.pool.ntp.org'
    - '+.ipv6.microsoft.com'
    - speedtest.cros.wr.pvp.net
    - network-test.debian.org
    - detectportal.firefox.com
    - cable.auth.com
    - miwifi.com
    - routerlogin.com
    - routerlogin.net
    - tendawifi.com
    - tendawifi.net
    - tplinklogin.net
    - tplinkwifi.net
    - '*.xiami.com'
    - tplinkrepeater.net
    - router.asus.com
    - '*.*.*.srv.nintendo.net'
    - '*.*.stun.playstation.net'
    - '*.openwrt.pool.ntp.org'
    - resolver1.opendns.com
    - 'GC._msDCS.*.*'
    - 'DC._msDCS.*.*'
    - 'PDC._msDCS.*.*'
  use-hosts: true
  nameserver:
    - '8.8.4.4'
    - '1.0.0.1'
    - \"https://1.0.0.1/dns-query\"
    - \"https://8.8.4.4/dns-query\"
";

    $parts = explode('proxies:', $content, 2);
    if (count($parts) == 2) {
        return $new_config_start . "\nproxies:" . $parts[1];
    } else {
        return $content;
    }
}

function saveSubscriptionContentToYaml($url, $filename) {
    global $download_path;

    if (strpbrk($filename, "!@#$%^&*()+=[]\\\';,/{}|\":<>?") !== false) {
        $message = "Filename contains illegal characters. Please use letters, numbers, dots, underscores, or hyphens.";
        logMessage($message);
        return $message;
    }

    if (!is_dir($download_path)) {
        if (!mkdir($download_path, 0755, true)) {
            $message = "Unable to create directory: $download_path";
            logMessage($message);
            return $message;
        }
    }

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    $subscription_data = curl_exec($ch);

    if (curl_errno($ch)) {
        $error_msg = curl_error($ch);
        curl_close($ch);
        $message = "cURL Error: $error_msg";
        logMessage($message);
        return $message;
    }
    curl_close($ch);

    if ($subscription_data === false || empty($subscription_data)) {
        $message = "Unable to retrieve subscription content. Please check if the link is correct.";
        logMessage($message);
        return $message;
    }

    if (base64_decode($subscription_data, true) !== false) {
        $decoded_data = base64_decode($subscription_data);
    } else {
        $decoded_data = $subscription_data;
    }

    $transformed_data = transformContent($decoded_data);

    $file_path = $download_path . $filename;
    $success = file_put_contents($file_path, $transformed_data) !== false;
    $message = $success ? "Content successfully saved to: $file_path" : "File save failed.";
    logMessage($message);
    return $message;
}

function generateShellScript() {
    global $subscription_file, $download_path, $php_script_path, $sh_script_path;

    $sh_script_content = <<<EOD
#!/bin/bash

SUBSCRIPTION_FILE='$subscription_file'
DOWNLOAD_PATH='$download_path'
DEST_PATH='/etc/neko/config/config.yaml'
PHP_SCRIPT_PATH='$php_script_path'

if [ ! -f "\$SUBSCRIPTION_FILE" ]; then
    echo "Subscription file not found: \$SUBSCRIPTION_FILE"
    exit 1
fi

SUBSCRIPTION_URL=\$(cat "\$SUBSCRIPTION_FILE")

php -f "\$PHP_SCRIPT_PATH" <<EOF
POST
subscription_url=\$SUBSCRIPTION_URL
filename=config.yaml
EOF

UPDATED_FILE="\$DOWNLOAD_PATH/config.yaml"
if [ ! -f "\$UPDATED_FILE" ]; then
    echo "Updated configuration file not found: \$UPDATED_FILE"
    exit 1
fi

mv "\$UPDATED_FILE" "\$DEST_PATH"

if [ \$? -eq 0 ]; then
    echo "Configuration file successfully updated and moved to \$DEST_PATH"
else
    echo "Failed to move configuration file to \$DEST_PATH"
    exit 1
fi
EOD;

    $success = file_put_contents($sh_script_path, $sh_script_content) !== false;
    logMessage($success ? "Shell script successfully created and given execute permission." : "Unable to create shell script file.");
    if ($success) {
        shell_exec("chmod +x $sh_script_path");
    }
    return $success ? "Shell script successfully created and given execute permission." : "Unable to create shell script file.";
}

function setupCronJob($cron_time) {
    global $sh_script_path;

    $cron_entry = "$cron_time $sh_script_path\n";
    $current_cron = shell_exec('crontab -l 2>/dev/null');
    
    if (strpos($current_cron, $sh_script_path) !== false) {
        $updated_cron = preg_replace('/.*' . preg_quote($sh_script_path, '/') . '/', $cron_entry, $current_cron);
    } else {
        $updated_cron = $current_cron . $cron_entry;
    }

    $success = file_put_contents('/tmp/cron.txt', $updated_cron) !== false;
    if ($success) {
        shell_exec('crontab /tmp/cron.txt');
    logMessage("Cron job successfully set to run at $cron_time.");
    return "Cron job successfully set to run at $cron_time.";
} else {
    logMessage("Unable to write to temporary Cron file.");
    return "Unable to write to temporary Cron file.";
    }
}

$result = '';
$cron_result = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['subscription_url']) && isset($_POST['filename'])) {
        $subscription_url = $_POST['subscription_url'];
        $filename = $_POST['filename'];

        if (empty($filename)) {
            $filename = 'config.yaml';
        }

        if (saveSubscriptionUrlToFile($subscription_url, $subscription_file)) {
            $result .= saveSubscriptionContentToYaml($subscription_url, $filename) . "<br>";
            $result .= generateShellScript() . "<br>";
        } else {
        return file_get_contents($file);
        }
    }

    if (isset($_POST['cron_time'])) {
        $cron_time = $_POST['cron_time'];
        $cron_result .= setupCronJob($cron_time) . "<br>";
    }
}

function getSubscriptionUrlFromFile($file) {
    if (file_exists($file)) {
        return file_get_contents($file);
    }
    return '';
}

$current_subscription_url = getSubscriptionUrlFromFile($subscription_file);
?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Personal - Neko</title>
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/neko.js"></script>
</head>
<body>
<style>
@media (max-width: 767px) {
    .row a {
        font-size: 9px; 
    }
}

.table-responsive {
    width: 100%;
}
</style>
<div class="container-sm container-bg callout border border-3 rounded-4 col-11">
    <div class="row">
        <a href="./index.php" class="col btn btn-lg">🏠 Home</a>
        <a href="./mihomo_manager.php" class="col btn btn-lg">📂 Mihomo</a>
        <a href="./singbox_manager.php" class="col btn btn-lg">🗂️ Sing-box</a>
        <a href="./box.php" class="col btn btn-lg">💹 Template</a>
        <a href="./personal.php" class="col btn btn-lg">📦 Personal</a>
        <h1 class="text-center p-2" style="margin-top: 2rem; margin-bottom: 1rem;">Mihomo Subscription Program（Clash）</h1>

        <div class="col-12">
            <div class="form-section">
                <form method="post">
                    <div class="mb-3">
                        <label for="subscription_url" class="form-label">Enter Subscription URL:</label>
                        <input type="text" class="form-control" id="subscription_url" name="subscription_url"
                               value="<?php echo htmlspecialchars($current_subscription_url); ?>" required>
                    </div>
                    <div class="mb-3">
                        <label for="filename" class="form-label">Enter Save Filename (Default: config.yaml):</label>
                        <input type="text" class="form-control" id="filename" name="filename"
                               value="<?php echo htmlspecialchars(isset($_POST['filename']) ? $_POST['filename'] : ''); ?>"
                               placeholder="config.yaml">
                    </div>
                    <button type="submit" class="btn btn-primary" name="action" value="update_subscription">Update Subscription</button>
                </form>
            </div>

            <div class="form-section mt-4">
                <form method="post">
                    <div class="mb-3">
                        <label for="cron_time" class="form-label">Set Cron Time (e.g., 0 3 * * *):</label>
                        <input type="text" class="form-control" id="cron_time" name="cron_time"
                               value="<?php echo htmlspecialchars(isset($_POST['cron_time']) ? $_POST['cron_time'] : '0 3 * * *'); ?>"
                               placeholder="0 3 * * *">
                    </div>
                    <button type="submit" class="btn btn-primary" name="action" value="update_cron">Update Cron Job</button>
                </form>
            </div>
        </div>

        <div class="help mt-4">
            <h2 class="text-center">Help Instructions</h2>
            <p>Welcome to the Mihomo Subscription Program! Please follow the steps below:：</p>
            <ul class="list-group">
                <li class="list-group-item"><strong>Enter Subscription URL:</strong> Enter your Clash subscription URL in the text box.</li>
                <li class="list-group-item"><strong>Enter Save Filename:</strong> Specify the filename to save the configuration file, default is "config.yaml".</li>
                <li class="list-group-item">Click the "Update Subscription" button, the system will download the subscription content, convert it, and save it.</li>
            </ul>
        </div>

        <div class="result mt-4">
            <?php echo nl2br(htmlspecialchars($result)); ?>
        </div>
        <div class="result mt-2">
            <?php echo nl2br(htmlspecialchars($cron_result)); ?>
        </div>
        </div>
    </div>
</div>
</body>
</html>
