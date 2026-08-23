// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PoPo';

  @override
  String get navSearch => 'Search';

  @override
  String get navResults => 'Results';

  @override
  String get navSaved => 'Saved';

  @override
  String get copy => 'Copy';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get stop => 'Stop';

  @override
  String get skip => 'Skip';

  @override
  String get searchEngines => 'Search engines';

  @override
  String get searchAction => 'Search';

  @override
  String get searchRunning => 'Searching…';

  @override
  String get noEnginesEnabled => 'No engines are enabled.';

  @override
  String get scanningTitle => 'Searching';

  @override
  String get scanFinished => 'Search finished';

  @override
  String configsFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString configs',
      one: '1 config',
    );
    return '$_temp0';
  }

  @override
  String soFarFromEngines(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'So far from $countString engines';
  }

  @override
  String fromEngines(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'From $countString engines';
  }

  @override
  String engineResults(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get engineNoResults => 'No results';

  @override
  String get engineSearching => 'Searching';

  @override
  String get engineQueued => 'Queued';

  @override
  String get engineBlocked => 'Blocked';

  @override
  String get engineCaptcha => 'Asked for a captcha';

  @override
  String get engineUnavailable => 'Unavailable';

  @override
  String get engineStopped => 'Stopped';

  @override
  String resultsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get sortByPing => 'Sort: ping';

  @override
  String get tabConfigs => 'Configs';

  @override
  String get tabProxies => 'Proxies';

  @override
  String get filterAll => 'All';

  @override
  String sourceLabel(String name) {
    return 'Source: $name';
  }

  @override
  String get configDetailTitle => 'Config detail';

  @override
  String get metaProtocol => 'Protocol';

  @override
  String get metaIpPort => 'IP and port';

  @override
  String get metaLastSuccess => 'Last successful test';

  @override
  String get metaSource => 'Source';

  @override
  String get copyLink => 'Copy link';

  @override
  String get testAgain => 'Test again';

  @override
  String get simpleIntro =>
      'Press one button and it will find the best way to connect, then connect you.';

  @override
  String get startSetup => 'Start setup';

  @override
  String get advancedMode => 'Advanced mode';

  @override
  String get pleaseWait => 'One moment';

  @override
  String stepOfSteps(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Step $currentString of $totalString';
  }

  @override
  String get stepSearchTitle => 'Searching the engines';

  @override
  String stepSearchNote(int engines, int results) {
    final intl.NumberFormat enginesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String enginesString = enginesNumberFormat.format(engines);
    final intl.NumberFormat resultsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String resultsString = resultsNumberFormat.format(results);

    return '$enginesString engines · $resultsString results';
  }

  @override
  String get stepHealthTitle => 'Checking health and speed';

  @override
  String stepHealthNote(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString healthy';
  }

  @override
  String get stepPickTitle => 'Picking the best option';

  @override
  String get stepPickNote => 'Lowest ping';

  @override
  String get stateDone => 'Done';

  @override
  String get stateRunning => 'In progress';

  @override
  String get stateWaiting => 'Waiting';

  @override
  String get ready => 'Ready';

  @override
  String get readyBody =>
      'A fast server was found.\nPress the button below to connect.';

  @override
  String get pickManually => 'Pick from the list yourself';

  @override
  String get connected => 'You are connected';

  @override
  String get pickServer => 'Pick a server';

  @override
  String get redoSetup => 'Run setup again for a fresh list';

  @override
  String get settings => 'Settings';

  @override
  String get settingAutoSearch => 'Automatic search';

  @override
  String settingEveryHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Every $countString hours';
  }

  @override
  String get settingPerEngineCap => 'Result cap per engine';

  @override
  String settingItems(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString items';
  }

  @override
  String get settingTestTimeout => 'Test timeout';

  @override
  String settingSeconds(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString seconds';
  }

  @override
  String get settingAutoRemoveDead => 'Remove dead configs automatically';

  @override
  String settingAfterFailedTests(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'After $countString failed tests';
  }

  @override
  String get settingSimpleMode => 'Simple mode';

  @override
  String get settingSimpleModeNote => 'One button, no settings';

  @override
  String get settingTheme => 'Theme';

  @override
  String get settingThemeValue => 'Amber · dark';

  @override
  String get settingLanguage => 'Language';

  @override
  String get settingKeywords => 'Search phrases';

  @override
  String settingKeywordsValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString phrases';
  }

  @override
  String get clearAllResults => 'Clear all results';

  @override
  String get savedTitle => 'Saved';

  @override
  String selectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString selected';
  }

  @override
  String get copyAll => 'Copy all';

  @override
  String get exportSubscription => 'Export subscription';

  @override
  String get qr => 'QR';

  @override
  String get testAll => 'Test all';

  @override
  String get keywordsTitle => 'Search phrases';

  @override
  String get keywordsIntro =>
      'These are what the app searches for. Edit them to change what it finds.';

  @override
  String get addKeywordHint => 'Add a new phrase…';

  @override
  String get addKeyword => 'Add';

  @override
  String get generatedPhrases => 'Generated automatically';

  @override
  String get customPhrases => 'Yours';

  @override
  String get presetSets => 'Preset sets';

  @override
  String phrasesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString phrases';
  }

  @override
  String get setProtocolNames => 'Protocol names';

  @override
  String get setFreshness => 'Month and year';

  @override
  String get setPersian => 'Persian phrases';

  @override
  String get setSiteScoped => 'Site-scoped (github, t.me)';

  @override
  String get setRawLinks => 'Raw subscription links';

  @override
  String get restoreDefaults => 'Restore defaults';

  @override
  String get keywordAlreadyExists => 'That phrase is already in the list.';

  @override
  String get noCustomKeywords => 'You have not added any phrases yet.';

  @override
  String get proxyDetailTitle => 'Proxy detail';

  @override
  String get badgePortOpen => 'Port open';

  @override
  String get metaType => 'Type';

  @override
  String get metaAddress => 'Address';

  @override
  String get metaAnonymity => 'Anonymity';

  @override
  String get metaHttpsSupport => 'HTTPS support';

  @override
  String get metaLastPortTest => 'Last port test';

  @override
  String get copyIpPort => 'Copy ip:port';

  @override
  String get testPort => 'Test port';

  @override
  String get openInV2rayNG => 'Open in V2rayNG';

  @override
  String get reportBroken => 'Report as broken';

  @override
  String get historyTitle => 'History';

  @override
  String runSummary(int results, int healthy, int engines) {
    final intl.NumberFormat resultsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String resultsString = resultsNumberFormat.format(results);
    final intl.NumberFormat healthyNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String healthyString = healthyNumberFormat.format(healthy);
    final intl.NumberFormat enginesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String enginesString = enginesNumberFormat.format(engines);

    return '$resultsString results · $healthyString healthy · $enginesString engines';
  }

  @override
  String get runAgain => 'Run again';

  @override
  String get importTitle => 'Import';

  @override
  String get subscriptionLink => 'Subscription link';

  @override
  String get fromClipboard => 'From clipboard';

  @override
  String historyToday(String time) {
    return 'Today $time';
  }

  @override
  String historyYesterday(String time) {
    return 'Yesterday $time';
  }

  @override
  String historyDaysAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString days ago';
  }

  @override
  String get errorStatesTitle => 'Empty and error states';

  @override
  String get emptyNoResultsTitle => 'Nothing found';

  @override
  String get emptyNoResultsBody =>
      'Make the phrases less specific, or enable more engines.';

  @override
  String get emptyNoResultsAction => 'Change phrases';

  @override
  String get errorOfflineTitle => 'No internet';

  @override
  String get errorOfflineBody => 'Check the device connection and try again.';

  @override
  String get errorOfflineAction => 'Try again';

  @override
  String errorCaptchaTitle(String engine) {
    return '$engine asked for a captcha';
  }

  @override
  String get errorCaptchaBody =>
      'That engine was skipped for now; the rest carried on.';

  @override
  String get errorCaptchaAction => 'Skip this engine';

  @override
  String get onboardTitle => 'Free lists, in one place';

  @override
  String get onboardBody =>
      'PoPo collects public servers, measures their speed and hands you the fastest.';

  @override
  String get warningTitle => 'One important note';

  @override
  String get warningBody =>
      'Strangers put these servers on the internet. They are fine for getting around a block, but do not enter your banking username or password over them.';

  @override
  String get gotIt => 'Got it, let\'s start';

  @override
  String get shareConnection => 'Share connection';

  @override
  String get serverOn => 'The server is on';

  @override
  String shareDevicesAndUsage(int devices, String usage) {
    final intl.NumberFormat devicesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String devicesString = devicesNumberFormat.format(devices);

    return '$devicesString devices connected · $usage today';
  }

  @override
  String get metaProxyAddress => 'Proxy address';

  @override
  String get metaHttpPort => 'HTTP port';

  @override
  String get metaSocksPort => 'SOCKS5 port';

  @override
  String get metaUsername => 'Username';

  @override
  String get metaPassword => 'Password';

  @override
  String get showConnectionQr => 'Show connection QR';

  @override
  String get changePassword => 'Change password';

  @override
  String get turnOnHotspot => 'Turn on hotspot';

  @override
  String get connectedDevices => 'Connected devices';

  @override
  String get deviceWorkLaptop => 'Work laptop';

  @override
  String get deviceLivingRoomTv => 'Living room TV';

  @override
  String get deviceSecondPhone => 'Second phone';

  @override
  String get deviceActive => 'Active';

  @override
  String get devicePendingApproval => 'Awaiting approval';

  @override
  String deviceUsageToday(String usage) {
    return '$usage today';
  }

  @override
  String get deviceLimit => 'Limit';

  @override
  String get deviceDisconnect => 'Disconnect';

  @override
  String get onlyApprovedDevices => 'Only approved devices may connect';

  @override
  String get pairingTitle => 'Connection guide';

  @override
  String get pairStep1Title => 'Turn on the phone\'s hotspot';

  @override
  String get pairStep1Body =>
      'Enable internet sharing in the phone\'s settings.';

  @override
  String get pairStep2Title => 'Open Wi-Fi settings on the second device';

  @override
  String get pairStep2Body => 'Connect it to that same hotspot.';

  @override
  String get pairStep3Title => 'Set the proxy to Manual';

  @override
  String get pairStep3Body => 'Enter the address and port below.';

  @override
  String get pairStep4Title => 'Save, or scan the QR';

  @override
  String get pairStep4Body =>
      'Once saved, its traffic goes through the tunnel.';

  @override
  String get copyAddressPort => 'Copy address and port';

  @override
  String get splitTitle => 'Split tunneling';

  @override
  String get splitBody => 'Choose which apps go through the tunnel.';

  @override
  String get appBrowser => 'Browser';

  @override
  String get appMessenger => 'Messenger';

  @override
  String get appBank => 'Bank';

  @override
  String get appVideo => 'Video streaming';

  @override
  String get routedThroughTunnel => 'Goes through the tunnel';

  @override
  String get routedDirect => 'Connects directly';

  @override
  String get allThroughTunnel => 'All through tunnel';

  @override
  String get noneThroughTunnel => 'None';

  @override
  String get securityTitle => 'Security and sync';

  @override
  String get settingKillSwitch => 'Cut internet if the tunnel drops';

  @override
  String get settingKillSwitchNote => 'Kill switch';

  @override
  String get settingSecureDns => 'Secure DNS';

  @override
  String get settingSecureDnsNote => '1.1.1.1 · DoH';

  @override
  String get settingAutoConnect => 'Connect automatically at startup';

  @override
  String get settingAutoConnectNote => 'Always';

  @override
  String get settingSyncLists => 'Sync lists between devices';

  @override
  String get settingSyncListsNote => 'Mobile and desktop';

  @override
  String get connectionLog => 'Connection log';

  @override
  String get desktopNavDashboard => 'Dashboard';

  @override
  String get desktopNavShare => 'Share connection';

  @override
  String get desktopNavHistory => 'History';

  @override
  String get desktopNavSimple => 'Simple mode';

  @override
  String get desktopNavSettings => 'Settings';

  @override
  String desktopConnectedTo(String country) {
    return 'Connected · $country';
  }

  @override
  String get statHealthyConfigs => 'Healthy configs';

  @override
  String get statHealthyProxies => 'Healthy proxies';

  @override
  String get statConnectedDevices => 'Connected devices';

  @override
  String get statUsageToday => 'Usage today';

  @override
  String get fastestOptions => 'Fastest options';

  @override
  String get redoSetupShort => 'Run setup again';

  @override
  String get trayTitle => 'Tray and quick tile';

  @override
  String get traySwitchServer => 'Switch server';

  @override
  String get trayShareOn => 'Share connection · on';

  @override
  String get trayExit => 'Exit';

  @override
  String get tileShare => 'Share';

  @override
  String devicesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString devices';
  }

  @override
  String get perPlatform => 'On each platform';

  @override
  String get surfaceAndroid => 'Quick tile and widget';

  @override
  String get surfaceIos => 'Shortcut and widget';

  @override
  String get surfaceWindows => 'System tray';

  @override
  String get surfaceMacos => 'Menu bar';

  @override
  String get surfaceLinux => 'CLI and GUI';

  @override
  String get galleryTitle => 'PoPo — phase 0';

  @override
  String gallerySubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString screens, built from the design system\'s tokens. No network, no server — interface only.';
  }

  @override
  String get runRealSearch => 'Run a real search (01 → 02)';

  @override
  String get availAndroidDesktop => 'Android and desktop';

  @override
  String get availAndroidOnly => 'Android only';

  @override
  String get availDesktopOnly => 'Desktop only';

  @override
  String seeResults(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'See $countString results';
  }

  @override
  String foundCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString found';
  }

  @override
  String get notTestedYet =>
      'Not tested yet — extraction and initial ranking only.';

  @override
  String get nothingFoundBody =>
      'Nothing was found. Enable more engines, or try again later.';

  @override
  String sourcesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString sources';
  }

  @override
  String get screenSearch => 'Search';

  @override
  String get screenScanning => 'Searching';

  @override
  String get screenResults => 'Results';

  @override
  String get screenConfigDetail => 'Config detail';

  @override
  String get screenSimpleStart => 'Start';

  @override
  String get screenSimpleSteps => 'Steps';

  @override
  String get screenSimpleReady => 'Ready';

  @override
  String get screenSimpleConnected => 'Connected';

  @override
  String get screenSettings => 'Settings';

  @override
  String get screenSaved => 'Saved';

  @override
  String get screenKeywords => 'Search phrases';

  @override
  String get screenProxyDetail => 'Proxy detail';

  @override
  String get screenHistory => 'History and import';

  @override
  String get screenErrors => 'Empty and error';

  @override
  String get screenOnboarding => 'Onboarding';

  @override
  String get screenProxyServer => 'Proxy server';

  @override
  String get screenDevices => 'Connected devices';

  @override
  String get screenPairing => 'Connection guide';

  @override
  String get screenSplitTunnel => 'Split tunneling';

  @override
  String get screenSecurity => 'Security and sync';

  @override
  String get screenDesktop => 'Desktop';

  @override
  String get screenTray => 'Tray and quick tile';

  @override
  String get runErrorNoEngines => 'No engines are enabled.';

  @override
  String get runErrorFailed => 'The search could not be completed.';

  @override
  String get placeNlAmsterdam => 'Netherlands · Amsterdam';

  @override
  String get placeDeFrankfurt => 'Germany · Frankfurt';

  @override
  String get placeFiHelsinki => 'Finland · Helsinki';

  @override
  String get placePlWarsaw => 'Poland · Warsaw';

  @override
  String get placeTrIstanbul => 'Türkiye · Istanbul';

  @override
  String get placeNl => 'Netherlands';

  @override
  String get listSeparator => ', ';

  @override
  String get languageSystem => 'Follow the device';
}
