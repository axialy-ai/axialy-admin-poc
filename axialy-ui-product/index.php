<?php
// /index.php
require_once 'includes/auth.php';
requireAuth();

// Get logged in username (legacy code)
$loggedInUsername = '';
if (isset($_SESSION['user_id'])) {
    require_once 'includes/db_connection.php';
    $stmt = $conn->prepare("SELECT username FROM ui_users WHERE id = ?");
    $stmt->bind_param("i", $_SESSION['user_id']);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($row = $result->fetch_assoc()) {
        $loggedInUsername = htmlspecialchars($row['username'], ENT_QUOTES, 'UTF-8');
    }
    $stmt->close();
}

// Paths to JSON configuration files
$menuJsonPath          = __DIR__ . '/config/control-panel-menu.json';
$accountActionsJsonPath= __DIR__ . '/config/account-actions.json';
$helpSupportJsonPath   = __DIR__ . '/config/support-actions.json';

// Initialize default configurations
$menuOptions = [];
$viewsDropdownConfig = [
    'backgroundImage' => '/assets/img/AxiaBA-Umbrella.png',
    'backgroundOpacity' => 0.8
];
$accountActions = [];
$helpSupportActions = [];

// Function to load and decode a JSON file
function loadJsonConfig($path) {
    if (file_exists($path)) {
        $jsonContent = file_get_contents($path);
        $data = json_decode($jsonContent, true);
        if (json_last_error() === JSON_ERROR_NONE) {
            return $data;
        } else {
            error_log("Error parsing JSON file at $path: " . json_last_error_msg());
        }
    } else {
        error_log("Error: JSON file not found at $path.");
    }
    return null;
}

// Load menu options
$menuData = loadJsonConfig($menuJsonPath);
if ($menuData) {
    $menuOptions = $menuData['menuOptions'] ?? [];
    $viewsDropdownConfig = $menuData['viewsDropdown'] ?? $viewsDropdownConfig;
}

// Load account actions
$accountActionsData = loadJsonConfig($accountActionsJsonPath);
if ($accountActionsData) {
    $accountActions = $accountActionsData['accountActions'] ?? [];
}

// Load help & support items
$helpSupportData = loadJsonConfig($helpSupportJsonPath);
if ($helpSupportData) {
    $helpSupportActions = $helpSupportData['supportActions'] ?? [];
}

// Use the config instance to get the version
require_once '/home/i17z4s936h3j/private_axiaba/includes/Config.php';

use AxiaBA\Config\Config;
$config = Config::getInstance();
$appVersion = $config['app_version'] ?: '1.x.x'; // fallback
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <!-- Meta Tags -->
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AxiaBA - Business Analysis</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">
    <!-- Our Stylesheets -->
    <link rel="stylesheet" href="assets/css/desktop.css" id="layout-css">
    <link rel="stylesheet" href="assets/css/generate-tab.css" id="generate-tab-css">
    <link rel="stylesheet" href="assets/css/home-tab.css" id="home-tab-css">
    <link rel="stylesheet" href="assets/css/refine-tab.css" id="refine-tab-css">
    <link rel="stylesheet" href="assets/css/refine-tab-overlays.css">
    <link rel="stylesheet" href="assets/css/dashboard-tab.css">
    <link rel="stylesheet" href="assets/css/overlay.css" id="overlay-css">
    <link rel="stylesheet" href="assets/css/support-tickets.css">
    <link rel="stylesheet" href="assets/css/content-review.css" id="content-review-css">
    <link rel="stylesheet" href="assets/css/content-revision.css" id="content-revision-css">
    <link rel="stylesheet" href="assets/css/settings-tab.css" id="settings-tab-css">
    <link rel="stylesheet" href="assets/css/publish-tab.css" id="publish-tab-css">
    <link rel="stylesheet" href="assets/css/account-actions.css" id="account-actions-css">
</head>
<body>
    <div class="page-container">
        <!-- Header Section -->
        <header class="page-header">
            <div class="product-logo" style="position: relative; display: inline-block;">
              <a href="https://axialy.ai" target="_blank" rel="noopener">
                <img src="assets/img/product_logo.png" alt="AxiaBA Logo"
                     style="height:44px; vertical-align: middle;">
              </a>
              <?php if (!empty($appVersion)): ?>
              <span style="
                position: absolute;
                bottom: 0;
                left: calc(100% + 6px);
                font-size: 0.618rem; 
                color: #caa23a;
              ">
                v<?php echo htmlspecialchars($appVersion, ENT_QUOTES, 'UTF-8'); ?>
              </span>
              <?php endif; ?>
            </div>
            <!-- Views Dropdown (Center) -->
            <div class="views-dropdown-container">
                <div class="views-dropdown" id="views-dropdown">
                    <select
                        id="views-menu"
                        aria-label="Select View"
                        data-background-image="<?php echo htmlspecialchars($viewsDropdownConfig['backgroundImage'] ?? '/assets/img/AxiaBA-Umbrella.png', ENT_QUOTES, 'UTF-8'); ?>"
                        data-background-opacity="<?php echo htmlspecialchars($viewsDropdownConfig['backgroundOpacity'] ?? '0.8', ENT_QUOTES, 'UTF-8'); ?>"
                    >
                        <?php if (!empty($menuOptions)): ?>
                            <?php foreach ($menuOptions as $index => $menuItem): ?>
                                <?php
                                    $name = htmlspecialchars($menuItem['name'], ENT_QUOTES, 'UTF-8');
                                    $tooltip = htmlspecialchars($menuItem['tooltip'], ENT_QUOTES, 'UTF-8');
                                    $target = htmlspecialchars($menuItem['target'], ENT_QUOTES, 'UTF-8');
                                    $selected = ($index === 0) ? ' selected' : '';
                                    $backgroundImage = htmlspecialchars($menuItem['backgroundImage'] ?? '/assets/img/AxiaBA-Umbrella.png', ENT_QUOTES, 'UTF-8');
                                    $backgroundOpacity = htmlspecialchars($menuItem['backgroundOpacity'] ?? '0.8', ENT_QUOTES, 'UTF-8');
                                ?>
                                <option
                                    value="<?php echo $target; ?>"
                                    <?php echo $selected; ?>
                                    data-background-image="<?php echo $backgroundImage; ?>"
                                    data-background-opacity="<?php echo $backgroundOpacity; ?>"
                                >
                                    <?php echo $name; ?>
                                </option>
                            <?php endforeach; ?>
                        <?php else: ?>
                            <option value="">No views available</option>
                        <?php endif; ?>
                    </select>
                </div>
            </div>
            <!-- Right Icons Container (settings + help) -->
            <div class="header-right-icons">
                <!-- Settings Icon + Dropdown -->
                <div class="settings">
                    <span
                        class="icon settings-icon"
                        data-tooltip="Account actions"
                        role="button"
                        tabindex="0"
                        aria-label="Account actions"
                    >⚙️</span>
                    <div class="settings-dropdown">
                        <div class="user-info">
                            <span class="dropdown-username"><?php echo $loggedInUsername; ?></span>
                        </div>
                        <ul>
                            <?php if (!empty($accountActions)): ?>
                                <?php foreach ($accountActions as $actionItem): ?>
                                    <?php
                                        if (!empty($actionItem['active'])) {
                                            $label = htmlspecialchars($actionItem['label'], ENT_QUOTES, 'UTF-8');
                                            $actionType = htmlspecialchars($actionItem['actionType'], ENT_QUOTES, 'UTF-8');
                                            $action = htmlspecialchars($actionItem['action'], ENT_QUOTES, 'UTF-8');
                                            if ($actionType === 'js') {
                                                $href = '#';
                                                $onclick = "onclick=\"$action\"";
                                            } elseif ($actionType === 'link') {
                                                $href = $action;
                                                $onclick = '';
                                            } else {
                                                continue;
                                            }
                                        } else {
                                            continue;
                                        }
                                    ?>
                                    <li><a href="<?php echo $href; ?>" <?php echo $onclick; ?>><?php echo $label; ?></a></li>
                                <?php endforeach; ?>
                            <?php else: ?>
                                <li>No account actions available.</li>
                            <?php endif; ?>
                        </ul>
                    </div>
                </div>
                <!-- Help Icon + Dropdown -->
                <div class="help">
                    <span
                        class="icon help-icon"
                        data-tooltip="Help & Support"
                        role="button"
                        tabindex="0"
                        aria-label="Help & Support"
                    >❓</span>
                    <div class="help-dropdown">
                        <ul>
                            <?php if (!empty($helpSupportActions)): ?>
                                <?php foreach ($helpSupportActions as $helpItem): ?>
                                    <?php
                                        if (!empty($helpItem['active'])) {
                                            $label = htmlspecialchars($helpItem['label'], ENT_QUOTES, 'UTF-8');
                                            $actionType = htmlspecialchars($helpItem['actionType'], ENT_QUOTES, 'UTF-8');
                                            $action = htmlspecialchars($helpItem['action'], ENT_QUOTES, 'UTF-8');
                                            if ($actionType === 'js') {
                                                $href = '#';
                                                $onclick = "onclick=\"$action\"";
                                            } elseif ($actionType === 'link') {
                                                $href = $action;
                                                $onclick = 'target="_blank"';
                                            } else {
                                                continue;
                                            }
                                        } else {
                                            continue;
                                        }
                                    ?>
                                    <li>
                                        <a href="<?php echo $href; ?>" <?php echo $onclick; ?>>
                                            <?php echo $label; ?>
                                        </a>
                                    </li>
                                <?php endforeach; ?>
                            <?php else: ?>
                                <li>No help/support actions available.</li>
                            <?php endif; ?>
                        </ul>
                    </div>
                </div>
            </div>
        </header>
        <!-- Upper Ribbon -->
        <div class="upper-ribbon"></div>
        <!-- Main Panel Container -->
        <div class="panel-container">
            <nav class="control-panel expanded" role="navigation" aria-label="Control Panel">
                <div class="panel-title">Views</div>
                <div class="pin-toggle pinned" id="pin-icon-control" role="button" tabindex="0" aria-label="Toggle Control Panel"></div>
                <div class="collapsed-title">Control Panel</div>
                <ul class="tab-options" role="tablist">
                    <?php if (!empty($menuOptions)): ?>
                        <?php foreach ($menuOptions as $index => $menuItem): ?>
                            <?php
                                $name = htmlspecialchars($menuItem['name'], ENT_QUOTES, 'UTF-8');
                                $tooltip = htmlspecialchars($menuItem['tooltip'], ENT_QUOTES, 'UTF-8');
                                $target = htmlspecialchars($menuItem['target'], ENT_QUOTES, 'UTF-8');
                                $activeClass = ($index === 0) ? ' active' : '';
                                $backgroundImage = htmlspecialchars($menuItem['backgroundImage'] ?? '/assets/img/AxiaBA-Umbrella.png', ENT_QUOTES, 'UTF-8');
                                $backgroundOpacity = htmlspecialchars($menuItem['backgroundOpacity'] ?? '0.8', ENT_QUOTES, 'UTF-8');
                            ?>
                            <li
                                class="list-group-item<?php echo $activeClass; ?>"
                                title="<?php echo $tooltip; ?>"
                                data-target="<?php echo $target; ?>"
                                data-background-image="<?php echo $backgroundImage; ?>"
                                data-background-opacity="<?php echo $backgroundOpacity; ?>"
                                role="tab"
                                tabindex="0"
                            >
                                <?php echo $name; ?>
                            </li>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <li class="list-group-item" role="tab" tabindex="0">No menu options available.</li>
                    <?php endif; ?>
                </ul>
            </nav>
            <main class="overview-panel" id="overview-panel" role="main">
                <!-- Content will be dynamically loaded here -->
            </main>
        </div>
        <!-- Lower Ribbon -->
        <div class="lower-ribbon"></div>
        <!-- Footer Section -->
        <footer class="page-footer">
            &copy; 2024 AxiaBA
        </footer>
    </div>

    <!-- Global AxiaBAConfig -->
    <script>
    window.AxiaBAConfig = {
        api_base_url: "<?php echo rtrim($config['api_base_url'], '/'); ?>",
        app_base_url: "<?php echo rtrim($config['app_base_url'], '/'); ?>",
        api_key: "<?php echo htmlspecialchars($config['internal_api_key'] ?? '', ENT_QUOTES, 'UTF-8'); ?>"
    };
    </script>

    <!-- Include Bootstrap JS before your custom scripts -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <!-- Updated reference: replaced deprecated terminology with "focus-area-version.js" -->
    <script src="js/input-text.js"></script>
    <script src="js/focus-areas.js"></script>
    <script src="js/export-csv.js"></script>
    <script src="js/overlay.js"></script>
    <script src="js/dynamic-ribbons.js"></script>
    <script src="js/process-feedback.js"></script>
    <script src="js/generate/save-data-enhancement.js"></script>
    <script src="js/focus-area-version.js"></script>
    <script src="js/home/home-tab.js"></script>
    <script src="js/account-actions.js"></script>
    <script src="js/support-tickets.js"></script>
    <script src="js/content-review.js"></script>
    <script src="js/content-revision.js"></script>
    <script src="js/apply-revisions-handler.js"></script>
    <script src="js/collate-feedback.js"></script>
    <script src="js/new-focus-area-overlay.js"></script>
    <script src="js/update-overview-panel.js"></script>
    <script src="js/modules/subscription-validation-module.js"></script>
    <script src="js/modules/tab-navigation-module.js"></script>
    <script src="js/modules/ui-utils-module.js"></script>
    <script src="js/layout.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
    document.addEventListener('DOMContentLoaded', function() {
        fetch('/get_user_email.php')
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    window.currentUserEmail = data.email;
                } else {
                    window.currentUserEmail = 'noreply@example.com';
                }
            })
            .catch(err => {
                console.error('Error fetching user email:', err);
                window.currentUserEmail = 'noreply@example.com';
            });
    });
    </script>
</body>
</html>
