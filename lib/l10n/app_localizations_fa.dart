// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class LFa extends L {
  LFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'PoPo';

  @override
  String get navSearch => 'جست‌وجو';

  @override
  String get navResults => 'نتایج';

  @override
  String get navSaved => 'ذخیره‌ها';

  @override
  String get copy => 'کپی';

  @override
  String get cancel => 'انصراف';

  @override
  String get save => 'ذخیره';

  @override
  String get connect => 'اتصال';

  @override
  String get disconnect => 'قطع اتصال';

  @override
  String get stop => 'توقف';

  @override
  String get skip => 'رد کردن';

  @override
  String get searchEngines => 'موتورهای جست‌وجو';

  @override
  String get searchAction => 'جست‌وجو';

  @override
  String get searchRunning => 'در حال جست‌وجو…';

  @override
  String get noEnginesEnabled => 'هیچ موتوری روشن نیست.';

  @override
  String get scanningTitle => 'در حال جست‌وجو';

  @override
  String get scanFinished => 'جست‌وجو تمام شد';

  @override
  String configsFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString کانفیگ';
  }

  @override
  String soFarFromEngines(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'تا اینجا از $countString موتور';
  }

  @override
  String fromEngines(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'از $countString موتور';
  }

  @override
  String engineResults(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString نتیجه';
  }

  @override
  String get engineNoResults => 'نتیجه‌ای نداشت';

  @override
  String get engineSearching => 'در حال جست‌وجو';

  @override
  String get engineQueued => 'در صف';

  @override
  String get engineBlocked => 'بلاک شد';

  @override
  String get engineCaptcha => 'کپچا خواست';

  @override
  String get engineUnavailable => 'در دسترس نبود';

  @override
  String get engineStopped => 'متوقف شد';

  @override
  String resultsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString نتیجه';
  }

  @override
  String get sortByPing => 'مرتب‌سازی: پینگ';

  @override
  String get tabConfigs => 'کانفیگ‌ها';

  @override
  String get tabProxies => 'پروکسی‌ها';

  @override
  String get filterAll => 'همه';

  @override
  String sourceLabel(String name) {
    return 'منبع: $name';
  }

  @override
  String get configDetailTitle => 'جزئیات کانفیگ';

  @override
  String get metaProtocol => 'پروتکل';

  @override
  String get metaIpPort => 'آی‌پی و پورت';

  @override
  String get metaLastSuccess => 'آخرین تست موفق';

  @override
  String get metaSource => 'منبع';

  @override
  String get copyLink => 'کپی لینک';

  @override
  String get testAgain => 'تست دوباره';

  @override
  String get simpleIntro =>
      'یک دکمه را بزنید تا خودش بهترین راه اتصال را پیدا کند و وصل شوید.';

  @override
  String get startSetup => 'شروع ستاپ';

  @override
  String get advancedMode => 'حالت پیشرفته';

  @override
  String get pleaseWait => 'کمی صبر کنید';

  @override
  String stepOfSteps(int current, int total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'مرحلهٔ $currentString از $totalString';
  }

  @override
  String get stepSearchTitle => 'جست‌وجو در موتورها';

  @override
  String stepSearchNote(int engines, int results) {
    final intl.NumberFormat enginesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String enginesString = enginesNumberFormat.format(engines);
    final intl.NumberFormat resultsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String resultsString = resultsNumberFormat.format(results);

    return '$enginesString موتور · $resultsString نتیجه';
  }

  @override
  String get stepHealthTitle => 'بررسی سلامت و سرعت';

  @override
  String stepHealthNote(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString مورد سالم';
  }

  @override
  String get stepPickTitle => 'انتخاب بهترین گزینه';

  @override
  String get stepPickNote => 'کم‌ترین پینگ';

  @override
  String get stateDone => 'انجام شد';

  @override
  String get stateRunning => 'در حال انجام';

  @override
  String get stateWaiting => 'در انتظار';

  @override
  String get ready => 'آماده است';

  @override
  String get readyBody =>
      'یک سرور سریع پیدا شد.\nبرای وصل شدن دکمهٔ زیر را بزنید.';

  @override
  String get pickManually => 'انتخاب دستی از لیست';

  @override
  String get connected => 'متصل هستید';

  @override
  String get pickServer => 'انتخاب سرور';

  @override
  String get redoSetup => 'ستاپ دوباره و لیست تازه';

  @override
  String get settings => 'تنظیمات';

  @override
  String get settingAutoSearch => 'جست‌وجوی خودکار';

  @override
  String settingEveryHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'هر $countString ساعت';
  }

  @override
  String get settingPerEngineCap => 'سقف نتایج هر موتور';

  @override
  String settingItems(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString مورد';
  }

  @override
  String get settingTestTimeout => 'تایم‌اوت تست';

  @override
  String settingSeconds(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ثانیه';
  }

  @override
  String get settingAutoRemoveDead => 'حذف خودکار کانفیگ مرده';

  @override
  String settingAfterFailedTests(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'پس از $countString تست ناموفق';
  }

  @override
  String get settingSimpleMode => 'حالت ساده';

  @override
  String get settingSimpleModeNote => 'یک دکمه، بدون تنظیمات';

  @override
  String get settingTheme => 'تم';

  @override
  String get settingThemeValue => 'کهربا · تیره';

  @override
  String get settingLanguage => 'زبان';

  @override
  String get settingKeywords => 'عبارت‌های کلیدی';

  @override
  String settingKeywordsValue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString عبارت';
  }

  @override
  String get clearAllResults => 'پاک‌کردن همهٔ نتایج';

  @override
  String get savedTitle => 'ذخیره‌شده‌ها';

  @override
  String selectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString انتخاب‌شده';
  }

  @override
  String get copyAll => 'کپی همه';

  @override
  String get exportSubscription => 'خروجی سابسکریپشن';

  @override
  String get qr => 'QR';

  @override
  String get testAll => 'تست همه';

  @override
  String get keywordsTitle => 'عبارت‌های کلیدی';

  @override
  String get keywordsIntro =>
      'اپ با این عبارت‌ها جست‌وجو می‌کند. با ویرایش آن‌ها نتیجه‌ها عوض می‌شود.';

  @override
  String get addKeywordHint => 'افزودن عبارت تازه…';

  @override
  String get addKeyword => 'افزودن';

  @override
  String get generatedPhrases => 'ساخته‌شده به‌صورت خودکار';

  @override
  String get customPhrases => 'عبارت‌های شما';

  @override
  String get presetSets => 'ست‌های آماده';

  @override
  String phrasesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString عبارت';
  }

  @override
  String get setProtocolNames => 'نام پروتکل‌ها';

  @override
  String get setFreshness => 'ماه و سال';

  @override
  String get setPersian => 'عبارت‌های فارسی';

  @override
  String get setSiteScoped => 'محدود به سایت (github، t.me)';

  @override
  String get setRawLinks => 'لینک خام سابسکریپشن';

  @override
  String get restoreDefaults => 'بازگرداندن پیش‌فرض‌ها';

  @override
  String get keywordAlreadyExists => 'این عبارت از قبل در لیست هست.';

  @override
  String get noCustomKeywords => 'هنوز عبارتی اضافه نکرده‌اید.';

  @override
  String get proxyDetailTitle => 'جزئیات پروکسی';

  @override
  String get badgePortOpen => 'پورت باز';

  @override
  String get metaType => 'نوع';

  @override
  String get metaAddress => 'آدرس';

  @override
  String get metaAnonymity => 'آنونیمیتی';

  @override
  String get metaHttpsSupport => 'پشتیبانی HTTPS';

  @override
  String get metaLastPortTest => 'آخرین تست پورت';

  @override
  String get copyIpPort => 'کپی ip:port';

  @override
  String get testPort => 'تست پورت';

  @override
  String get openInV2rayNG => 'بازکردن در V2rayNG';

  @override
  String get reportBroken => 'گزارش خراب‌بودن';

  @override
  String get historyTitle => 'تاریخچه';

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

    return '$resultsString نتیجه · $healthyString سالم · $enginesString موتور';
  }

  @override
  String get runAgain => 'اجرای دوباره';

  @override
  String get importTitle => 'ایمپورت';

  @override
  String get subscriptionLink => 'لینک سابسکریپشن';

  @override
  String get fromClipboard => 'از کلیپ‌بورد';

  @override
  String historyToday(String time) {
    return 'امروز $time';
  }

  @override
  String historyYesterday(String time) {
    return 'دیروز $time';
  }

  @override
  String historyDaysAgo(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString روز پیش';
  }

  @override
  String get errorStatesTitle => 'حالت‌های خالی و خطا';

  @override
  String get emptyNoResultsTitle => 'نتیجه‌ای پیدا نشد';

  @override
  String get emptyNoResultsBody =>
      'عبارت‌های کلیدی را کم‌تر خاص کنید یا موتور بیشتری روشن کنید.';

  @override
  String get emptyNoResultsAction => 'تغییر عبارت‌ها';

  @override
  String get errorOfflineTitle => 'اینترنت قطع است';

  @override
  String get errorOfflineBody =>
      'اتصال دستگاه را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get errorOfflineAction => 'تلاش دوباره';

  @override
  String errorCaptchaTitle(String engine) {
    return '$engine کپچا خواست';
  }

  @override
  String get errorCaptchaBody =>
      'این موتور موقتاً کنار گذاشته شد؛ بقیه ادامه دادند.';

  @override
  String get errorCaptchaAction => 'رد کردن این موتور';

  @override
  String get onboardTitle => 'لیست‌های رایگان، یک‌جا';

  @override
  String get onboardBody =>
      'PoPo سرورهای عمومی را جمع می‌کند، سرعتشان را می‌سنجد و سریع‌ترین را به شما می‌دهد.';

  @override
  String get warningTitle => 'یک نکتهٔ مهم';

  @override
  String get warningBody =>
      'این سرورها را افراد ناشناس روی اینترنت گذاشته‌اند. برای عبور از محدودیت خوب‌اند، ولی نام کاربری و رمز بانکی خود را روی آن‌ها وارد نکنید.';

  @override
  String get gotIt => 'متوجه شدم، شروع کنیم';

  @override
  String get shareConnection => 'اشتراک اتصال';

  @override
  String get serverOn => 'سرور روشن است';

  @override
  String shareDevicesAndUsage(int devices, String usage) {
    final intl.NumberFormat devicesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String devicesString = devicesNumberFormat.format(devices);

    return '$devicesString دستگاه وصل است · $usage امروز';
  }

  @override
  String get metaProxyAddress => 'آدرس پروکسی';

  @override
  String get metaHttpPort => 'پورت HTTP';

  @override
  String get metaSocksPort => 'پورت SOCKS5';

  @override
  String get metaUsername => 'نام کاربری';

  @override
  String get metaPassword => 'رمز';

  @override
  String get showConnectionQr => 'نمایش کد QR اتصال';

  @override
  String get changePassword => 'تغییر رمز';

  @override
  String get turnOnHotspot => 'روشن‌کردن هات‌اسپات';

  @override
  String get connectedDevices => 'دستگاه‌های وصل';

  @override
  String get deviceWorkLaptop => 'لپ‌تاپ کار';

  @override
  String get deviceLivingRoomTv => 'تلویزیون پذیرایی';

  @override
  String get deviceSecondPhone => 'موبایل دوم';

  @override
  String get deviceActive => 'فعال';

  @override
  String get devicePendingApproval => 'در انتظار تأیید';

  @override
  String deviceUsageToday(String usage) {
    return '$usage امروز';
  }

  @override
  String get deviceLimit => 'محدودکردن';

  @override
  String get deviceDisconnect => 'قطع';

  @override
  String get onlyApprovedDevices => 'فقط دستگاه‌های تأییدشده وصل شوند';

  @override
  String get pairingTitle => 'راهنمای اتصال';

  @override
  String get pairStep1Title => 'هات‌اسپات گوشی را روشن کنید';

  @override
  String get pairStep1Body => 'از تنظیمات گوشی، اشتراک اینترنت را فعال کنید.';

  @override
  String get pairStep2Title => 'روی دستگاه دوم به تنظیمات Wi-Fi بروید';

  @override
  String get pairStep2Body => 'به همان هات‌اسپات وصل شوید.';

  @override
  String get pairStep3Title => 'پروکسی را روی Manual بگذارید';

  @override
  String get pairStep3Body => 'آدرس و پورت زیر را وارد کنید.';

  @override
  String get pairStep4Title => 'ذخیره کنید یا QR را اسکن کنید';

  @override
  String get pairStep4Body => 'بعد از ذخیره، اینترنت از تونل عبور می‌کند.';

  @override
  String get copyAddressPort => 'کپی آدرس و پورت';

  @override
  String get splitTitle => 'تفکیک ترافیک';

  @override
  String get splitBody => 'انتخاب کنید کدام برنامه از تونل رد شود.';

  @override
  String get appBrowser => 'مرورگر';

  @override
  String get appMessenger => 'پیام‌رسان';

  @override
  String get appBank => 'بانک';

  @override
  String get appVideo => 'پخش ویدیو';

  @override
  String get routedThroughTunnel => 'از تونل عبور می‌کند';

  @override
  String get routedDirect => 'مستقیم وصل می‌شود';

  @override
  String get allThroughTunnel => 'همه از تونل';

  @override
  String get noneThroughTunnel => 'هیچ‌کدام';

  @override
  String get securityTitle => 'امنیت و همگام‌سازی';

  @override
  String get settingKillSwitch => 'قطع اینترنت هنگام افت تونل';

  @override
  String get settingKillSwitchNote => 'Kill switch';

  @override
  String get settingSecureDns => 'DNS امن';

  @override
  String get settingSecureDnsNote => '1.1.1.1 · DoH';

  @override
  String get settingAutoConnect => 'اتصال خودکار هنگام روشن شدن';

  @override
  String get settingAutoConnectNote => 'همیشه';

  @override
  String get settingSyncLists => 'همگام‌سازی لیست‌ها بین دستگاه‌ها';

  @override
  String get settingSyncListsNote => 'موبایل و دسکتاپ';

  @override
  String get connectionLog => 'لاگ اتصال';

  @override
  String get desktopNavDashboard => 'داشبورد';

  @override
  String get desktopNavShare => 'اشتراک اتصال';

  @override
  String get desktopNavHistory => 'تاریخچه';

  @override
  String get desktopNavSimple => 'حالت ساده';

  @override
  String get desktopNavSettings => 'تنظیمات';

  @override
  String desktopConnectedTo(String country) {
    return 'متصل · $country';
  }

  @override
  String get statHealthyConfigs => 'کانفیگ سالم';

  @override
  String get statHealthyProxies => 'پروکسی سالم';

  @override
  String get statConnectedDevices => 'دستگاه‌های وصل';

  @override
  String get statUsageToday => 'مصرف امروز';

  @override
  String get fastestOptions => 'سریع‌ترین گزینه‌ها';

  @override
  String get redoSetupShort => 'ستاپ دوباره';

  @override
  String get trayTitle => 'سینی سیستم و کوییک‌تایل';

  @override
  String get traySwitchServer => 'تعویض سرور';

  @override
  String get trayShareOn => 'اشتراک اتصال · روشن';

  @override
  String get trayExit => 'خروج';

  @override
  String get tileShare => 'اشتراک';

  @override
  String devicesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString دستگاه';
  }

  @override
  String get perPlatform => 'روی هر پلتفرم';

  @override
  String get surfaceAndroid => 'کوییک‌تایل و ویجت';

  @override
  String get surfaceIos => 'میان‌بر و ویجت';

  @override
  String get surfaceWindows => 'سینی سیستم';

  @override
  String get surfaceMacos => 'نوار منو';

  @override
  String get surfaceLinux => 'CLI و GUI';

  @override
  String get galleryTitle => 'PoPo — فاز ۰';

  @override
  String gallerySubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString صفحه، ساخته‌شده از توکن‌های دیزاین‌سیستم. بدون شبکه، بدون سرور — فقط رابط کاربری.';
  }

  @override
  String get runRealSearch => 'اجرای واقعی جست‌وجو (۰۱ → ۰۲)';

  @override
  String get availAndroidDesktop => 'اندروید و دسکتاپ';

  @override
  String get availAndroidOnly => 'فقط اندروید';

  @override
  String get availDesktopOnly => 'فقط دسکتاپ';

  @override
  String seeResults(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'دیدن $countString نتیجه';
  }

  @override
  String foundCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString مورد پیدا شد';
  }

  @override
  String get notTestedYet =>
      'هنوز تست نشده‌اند — فقط استخراج و رتبه‌بندی اولیه.';

  @override
  String get nothingFoundBody =>
      'چیزی پیدا نشد. موتورهای بیشتری روشن کنید یا بعداً دوباره تلاش کنید.';

  @override
  String sourcesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString منبع';
  }

  @override
  String get screenSearch => 'جست‌وجو';

  @override
  String get screenScanning => 'در حال جست‌وجو';

  @override
  String get screenResults => 'نتایج';

  @override
  String get screenConfigDetail => 'جزئیات کانفیگ';

  @override
  String get screenSimpleStart => 'شروع';

  @override
  String get screenSimpleSteps => 'مراحل';

  @override
  String get screenSimpleReady => 'آماده';

  @override
  String get screenSimpleConnected => 'متصل';

  @override
  String get screenSettings => 'تنظیمات';

  @override
  String get screenSaved => 'ذخیره‌شده‌ها';

  @override
  String get screenKeywords => 'عبارت‌های کلیدی';

  @override
  String get screenProxyDetail => 'جزئیات پروکسی';

  @override
  String get screenHistory => 'تاریخچه و ایمپورت';

  @override
  String get screenErrors => 'خالی و خطا';

  @override
  String get screenOnboarding => 'آنبوردینگ';

  @override
  String get screenProxyServer => 'سرور پروکسی';

  @override
  String get screenDevices => 'دستگاه‌های وصل';

  @override
  String get screenPairing => 'راهنمای اتصال';

  @override
  String get screenSplitTunnel => 'تفکیک ترافیک';

  @override
  String get screenSecurity => 'امنیت و همگام‌سازی';

  @override
  String get screenDesktop => 'دسکتاپ';

  @override
  String get screenTray => 'سینی و کوییک‌تایل';

  @override
  String get runErrorNoEngines => 'هیچ موتوری روشن نیست.';

  @override
  String get runErrorFailed => 'جست‌وجو کامل نشد.';

  @override
  String get placeNlAmsterdam => 'هلند · آمستردام';

  @override
  String get placeDeFrankfurt => 'آلمان · فرانکفورت';

  @override
  String get placeFiHelsinki => 'فنلاند · هلسینکی';

  @override
  String get placePlWarsaw => 'لهستان · ورشو';

  @override
  String get placeTrIstanbul => 'ترکیه · استانبول';

  @override
  String get placeNl => 'هلند';

  @override
  String get listSeparator => '، ';

  @override
  String get languageSystem => 'مطابق دستگاه';

  @override
  String get noResultsYet =>
      'هنوز نتیجه‌ای نیست. جست‌وجو کنید یا سابسکریپشن ایمپورت کنید.';

  @override
  String get probingUnsupported =>
      'روی این پلتفرم پینگ اندازه‌گیری نمی‌شود، پس چیزی مرده علامت نخورده.';

  @override
  String get retestAll => 'تست دوباره';

  @override
  String importedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString مورد ایمپورت شد';
  }

  @override
  String get importedNothing => 'در آن متن چیز قابل‌تشخیصی نبود.';

  @override
  String get clipboardEmpty => 'کلیپ‌بورد خالی است.';

  @override
  String get pasteSubscription => 'لینک سابسکریپشن یا متن کانفیگ را بچسبانید';

  @override
  String get importAction => 'ایمپورت';

  @override
  String get savedEmpty => 'هنوز چیزی ذخیره نشده.';

  @override
  String get unsaveSelected => 'حذف انتخاب‌شده‌ها';

  @override
  String get copied => 'کپی شد';

  @override
  String get testing => 'در حال تست';

  @override
  String get picking => 'انتخاب بهترین گزینه';

  @override
  String get stageSearching => 'جست‌وجو در موتورها';

  @override
  String get noHealthyFound =>
      'چیز قابل‌استفاده‌ای پیدا نشد. دوباره تلاش کنید یا موتور بیشتری روشن کنید.';

  @override
  String get openDetail => 'جزئیات';

  @override
  String get tunnelUnavailable =>
      'هستهٔ تونل در این بیلد ساخته نشده، پس اتصال در دسترس نیست. کشف و تست کار می‌کنند.';

  @override
  String get permissionDeclined =>
      'PoPo برای عبور دادن ترافیک به اجازهٔ VPN نیاز دارد. بدون آن چیزی وصل نمی‌شود.';

  @override
  String get connectFailed => 'اتصال برقرار نشد. سرور دیگری را امتحان کنید.';

  @override
  String get connecting => 'در حال اتصال…';

  @override
  String get disconnecting => 'در حال قطع…';

  @override
  String get connectionOptions => 'اتصال';

  @override
  String get settingSharingNote => 'دستگاه‌های نزدیک از این اتصال استفاده کنند';

  @override
  String get settingSplitTunnelNote =>
      'انتخاب اینکه کدام برنامه‌ها از تونل رد شوند';

  @override
  String get settingSecurityNote => 'قطع‌کن اضطراری، DNS و گزارش اتصال';
}
