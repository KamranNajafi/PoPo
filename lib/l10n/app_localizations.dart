import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PoPo'**
  String get appName;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get navResults;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @searchEngines.
  ///
  /// In en, this message translates to:
  /// **'Search engines'**
  String get searchEngines;

  /// No description provided for @searchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchAction;

  /// No description provided for @searchRunning.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searchRunning;

  /// No description provided for @noEnginesEnabled.
  ///
  /// In en, this message translates to:
  /// **'No engines are enabled.'**
  String get noEnginesEnabled;

  /// No description provided for @scanningTitle.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get scanningTitle;

  /// No description provided for @scanFinished.
  ///
  /// In en, this message translates to:
  /// **'Search finished'**
  String get scanFinished;

  /// No description provided for @configsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 config} other{{count} configs}}'**
  String configsFound(int count);

  /// No description provided for @soFarFromEngines.
  ///
  /// In en, this message translates to:
  /// **'So far from {count} engines'**
  String soFarFromEngines(int count);

  /// No description provided for @fromEngines.
  ///
  /// In en, this message translates to:
  /// **'From {count} engines'**
  String fromEngines(int count);

  /// No description provided for @engineResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String engineResults(int count);

  /// No description provided for @engineNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get engineNoResults;

  /// No description provided for @engineSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get engineSearching;

  /// No description provided for @engineQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get engineQueued;

  /// No description provided for @engineBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get engineBlocked;

  /// No description provided for @engineCaptcha.
  ///
  /// In en, this message translates to:
  /// **'Asked for a captcha'**
  String get engineCaptcha;

  /// No description provided for @engineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get engineUnavailable;

  /// No description provided for @engineStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get engineStopped;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String resultsCount(int count);

  /// No description provided for @sortByPing.
  ///
  /// In en, this message translates to:
  /// **'Sort: ping'**
  String get sortByPing;

  /// No description provided for @tabConfigs.
  ///
  /// In en, this message translates to:
  /// **'Configs'**
  String get tabConfigs;

  /// No description provided for @tabProxies.
  ///
  /// In en, this message translates to:
  /// **'Proxies'**
  String get tabProxies;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source: {name}'**
  String sourceLabel(String name);

  /// No description provided for @configDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Config detail'**
  String get configDetailTitle;

  /// No description provided for @metaProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get metaProtocol;

  /// No description provided for @metaIpPort.
  ///
  /// In en, this message translates to:
  /// **'IP and port'**
  String get metaIpPort;

  /// No description provided for @metaLastSuccess.
  ///
  /// In en, this message translates to:
  /// **'Last successful test'**
  String get metaLastSuccess;

  /// No description provided for @metaSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get metaSource;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @testAgain.
  ///
  /// In en, this message translates to:
  /// **'Test again'**
  String get testAgain;

  /// No description provided for @simpleIntro.
  ///
  /// In en, this message translates to:
  /// **'Press one button and it will find the best way to connect, then connect you.'**
  String get simpleIntro;

  /// No description provided for @startSetup.
  ///
  /// In en, this message translates to:
  /// **'Start setup'**
  String get startSetup;

  /// No description provided for @advancedMode.
  ///
  /// In en, this message translates to:
  /// **'Advanced mode'**
  String get advancedMode;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'One moment'**
  String get pleaseWait;

  /// No description provided for @stepOfSteps.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOfSteps(int current, int total);

  /// No description provided for @stepSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Searching the engines'**
  String get stepSearchTitle;

  /// No description provided for @stepSearchNote.
  ///
  /// In en, this message translates to:
  /// **'{engines} engines · {results} results'**
  String stepSearchNote(int engines, int results);

  /// No description provided for @stepHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking health and speed'**
  String get stepHealthTitle;

  /// No description provided for @stepHealthNote.
  ///
  /// In en, this message translates to:
  /// **'{count} healthy'**
  String stepHealthNote(int count);

  /// No description provided for @stepPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Picking the best option'**
  String get stepPickTitle;

  /// No description provided for @stepPickNote.
  ///
  /// In en, this message translates to:
  /// **'Lowest ping'**
  String get stepPickNote;

  /// No description provided for @stateDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stateDone;

  /// No description provided for @stateRunning.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get stateRunning;

  /// No description provided for @stateWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get stateWaiting;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @readyBody.
  ///
  /// In en, this message translates to:
  /// **'A fast server was found.\nPress the button below to connect.'**
  String get readyBody;

  /// No description provided for @pickManually.
  ///
  /// In en, this message translates to:
  /// **'Pick from the list yourself'**
  String get pickManually;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'You are connected'**
  String get connected;

  /// No description provided for @pickServer.
  ///
  /// In en, this message translates to:
  /// **'Pick a server'**
  String get pickServer;

  /// No description provided for @redoSetup.
  ///
  /// In en, this message translates to:
  /// **'Run setup again for a fresh list'**
  String get redoSetup;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingAutoSearch.
  ///
  /// In en, this message translates to:
  /// **'Automatic search'**
  String get settingAutoSearch;

  /// No description provided for @settingEveryHours.
  ///
  /// In en, this message translates to:
  /// **'Every {count} hours'**
  String settingEveryHours(int count);

  /// No description provided for @settingPerEngineCap.
  ///
  /// In en, this message translates to:
  /// **'Result cap per engine'**
  String get settingPerEngineCap;

  /// No description provided for @settingItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String settingItems(int count);

  /// No description provided for @settingTestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Test timeout'**
  String get settingTestTimeout;

  /// No description provided for @settingSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String settingSeconds(int count);

  /// No description provided for @settingAutoRemoveDead.
  ///
  /// In en, this message translates to:
  /// **'Remove dead configs automatically'**
  String get settingAutoRemoveDead;

  /// No description provided for @settingAfterFailedTests.
  ///
  /// In en, this message translates to:
  /// **'After {count} failed tests'**
  String settingAfterFailedTests(int count);

  /// No description provided for @settingSimpleMode.
  ///
  /// In en, this message translates to:
  /// **'Simple mode'**
  String get settingSimpleMode;

  /// No description provided for @settingSimpleModeNote.
  ///
  /// In en, this message translates to:
  /// **'One button, no settings'**
  String get settingSimpleModeNote;

  /// No description provided for @settingTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingTheme;

  /// No description provided for @settingThemeValue.
  ///
  /// In en, this message translates to:
  /// **'Amber · dark'**
  String get settingThemeValue;

  /// No description provided for @settingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingLanguage;

  /// No description provided for @settingKeywords.
  ///
  /// In en, this message translates to:
  /// **'Search phrases'**
  String get settingKeywords;

  /// No description provided for @settingKeywordsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} phrases'**
  String settingKeywordsValue(int count);

  /// No description provided for @clearAllResults.
  ///
  /// In en, this message translates to:
  /// **'Clear all results'**
  String get clearAllResults;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get copyAll;

  /// No description provided for @exportSubscription.
  ///
  /// In en, this message translates to:
  /// **'Export subscription'**
  String get exportSubscription;

  /// No description provided for @qr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get qr;

  /// No description provided for @testAll.
  ///
  /// In en, this message translates to:
  /// **'Test all'**
  String get testAll;

  /// No description provided for @keywordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Search phrases'**
  String get keywordsTitle;

  /// No description provided for @keywordsIntro.
  ///
  /// In en, this message translates to:
  /// **'These are what the app searches for. Edit them to change what it finds.'**
  String get keywordsIntro;

  /// No description provided for @addKeywordHint.
  ///
  /// In en, this message translates to:
  /// **'Add a new phrase…'**
  String get addKeywordHint;

  /// No description provided for @addKeyword.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addKeyword;

  /// No description provided for @generatedPhrases.
  ///
  /// In en, this message translates to:
  /// **'Generated automatically'**
  String get generatedPhrases;

  /// No description provided for @customPhrases.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get customPhrases;

  /// No description provided for @presetSets.
  ///
  /// In en, this message translates to:
  /// **'Preset sets'**
  String get presetSets;

  /// No description provided for @phrasesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} phrases'**
  String phrasesCount(int count);

  /// No description provided for @setProtocolNames.
  ///
  /// In en, this message translates to:
  /// **'Protocol names'**
  String get setProtocolNames;

  /// No description provided for @setFreshness.
  ///
  /// In en, this message translates to:
  /// **'Month and year'**
  String get setFreshness;

  /// No description provided for @setPersian.
  ///
  /// In en, this message translates to:
  /// **'Persian phrases'**
  String get setPersian;

  /// No description provided for @setSiteScoped.
  ///
  /// In en, this message translates to:
  /// **'Site-scoped (github, t.me)'**
  String get setSiteScoped;

  /// No description provided for @setRawLinks.
  ///
  /// In en, this message translates to:
  /// **'Raw subscription links'**
  String get setRawLinks;

  /// No description provided for @restoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get restoreDefaults;

  /// No description provided for @keywordAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'That phrase is already in the list.'**
  String get keywordAlreadyExists;

  /// No description provided for @noCustomKeywords.
  ///
  /// In en, this message translates to:
  /// **'You have not added any phrases yet.'**
  String get noCustomKeywords;

  /// No description provided for @proxyDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Proxy detail'**
  String get proxyDetailTitle;

  /// No description provided for @badgePortOpen.
  ///
  /// In en, this message translates to:
  /// **'Port open'**
  String get badgePortOpen;

  /// No description provided for @metaType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get metaType;

  /// No description provided for @metaAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get metaAddress;

  /// No description provided for @metaAnonymity.
  ///
  /// In en, this message translates to:
  /// **'Anonymity'**
  String get metaAnonymity;

  /// No description provided for @metaHttpsSupport.
  ///
  /// In en, this message translates to:
  /// **'HTTPS support'**
  String get metaHttpsSupport;

  /// No description provided for @metaLastPortTest.
  ///
  /// In en, this message translates to:
  /// **'Last port test'**
  String get metaLastPortTest;

  /// No description provided for @copyIpPort.
  ///
  /// In en, this message translates to:
  /// **'Copy ip:port'**
  String get copyIpPort;

  /// No description provided for @testPort.
  ///
  /// In en, this message translates to:
  /// **'Test port'**
  String get testPort;

  /// No description provided for @openInV2rayNG.
  ///
  /// In en, this message translates to:
  /// **'Open in V2rayNG'**
  String get openInV2rayNG;

  /// No description provided for @reportBroken.
  ///
  /// In en, this message translates to:
  /// **'Report as broken'**
  String get reportBroken;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @runSummary.
  ///
  /// In en, this message translates to:
  /// **'{results} results · {healthy} healthy · {engines} engines'**
  String runSummary(int results, int healthy, int engines);

  /// No description provided for @runAgain.
  ///
  /// In en, this message translates to:
  /// **'Run again'**
  String get runAgain;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @subscriptionLink.
  ///
  /// In en, this message translates to:
  /// **'Subscription link'**
  String get subscriptionLink;

  /// No description provided for @fromClipboard.
  ///
  /// In en, this message translates to:
  /// **'From clipboard'**
  String get fromClipboard;

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String historyToday(String time);

  /// No description provided for @historyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String historyYesterday(String time);

  /// No description provided for @historyDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String historyDaysAgo(int count);

  /// No description provided for @errorStatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty and error states'**
  String get errorStatesTitle;

  /// No description provided for @emptyNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get emptyNoResultsTitle;

  /// No description provided for @emptyNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Make the phrases less specific, or enable more engines.'**
  String get emptyNoResultsBody;

  /// No description provided for @emptyNoResultsAction.
  ///
  /// In en, this message translates to:
  /// **'Change phrases'**
  String get emptyNoResultsAction;

  /// No description provided for @errorOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet'**
  String get errorOfflineTitle;

  /// No description provided for @errorOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Check the device connection and try again.'**
  String get errorOfflineBody;

  /// No description provided for @errorOfflineAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get errorOfflineAction;

  /// No description provided for @errorCaptchaTitle.
  ///
  /// In en, this message translates to:
  /// **'{engine} asked for a captcha'**
  String errorCaptchaTitle(String engine);

  /// No description provided for @errorCaptchaBody.
  ///
  /// In en, this message translates to:
  /// **'That engine was skipped for now; the rest carried on.'**
  String get errorCaptchaBody;

  /// No description provided for @errorCaptchaAction.
  ///
  /// In en, this message translates to:
  /// **'Skip this engine'**
  String get errorCaptchaAction;

  /// No description provided for @onboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Free lists, in one place'**
  String get onboardTitle;

  /// No description provided for @onboardBody.
  ///
  /// In en, this message translates to:
  /// **'PoPo collects public servers, measures their speed and hands you the fastest.'**
  String get onboardBody;

  /// No description provided for @warningTitle.
  ///
  /// In en, this message translates to:
  /// **'One important note'**
  String get warningTitle;

  /// No description provided for @warningBody.
  ///
  /// In en, this message translates to:
  /// **'Strangers put these servers on the internet. They are fine for getting around a block, but do not enter your banking username or password over them.'**
  String get warningBody;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it, let\'s start'**
  String get gotIt;

  /// No description provided for @shareConnection.
  ///
  /// In en, this message translates to:
  /// **'Share connection'**
  String get shareConnection;

  /// No description provided for @serverOn.
  ///
  /// In en, this message translates to:
  /// **'The server is on'**
  String get serverOn;

  /// No description provided for @shareDevicesAndUsage.
  ///
  /// In en, this message translates to:
  /// **'{devices} devices connected · {usage} today'**
  String shareDevicesAndUsage(int devices, String usage);

  /// No description provided for @metaProxyAddress.
  ///
  /// In en, this message translates to:
  /// **'Proxy address'**
  String get metaProxyAddress;

  /// No description provided for @metaHttpPort.
  ///
  /// In en, this message translates to:
  /// **'HTTP port'**
  String get metaHttpPort;

  /// No description provided for @metaSocksPort.
  ///
  /// In en, this message translates to:
  /// **'SOCKS5 port'**
  String get metaSocksPort;

  /// No description provided for @metaUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get metaUsername;

  /// No description provided for @metaPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get metaPassword;

  /// No description provided for @showConnectionQr.
  ///
  /// In en, this message translates to:
  /// **'Show connection QR'**
  String get showConnectionQr;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @turnOnHotspot.
  ///
  /// In en, this message translates to:
  /// **'Turn on hotspot'**
  String get turnOnHotspot;

  /// No description provided for @connectedDevices.
  ///
  /// In en, this message translates to:
  /// **'Connected devices'**
  String get connectedDevices;

  /// No description provided for @deviceWorkLaptop.
  ///
  /// In en, this message translates to:
  /// **'Work laptop'**
  String get deviceWorkLaptop;

  /// No description provided for @deviceLivingRoomTv.
  ///
  /// In en, this message translates to:
  /// **'Living room TV'**
  String get deviceLivingRoomTv;

  /// No description provided for @deviceSecondPhone.
  ///
  /// In en, this message translates to:
  /// **'Second phone'**
  String get deviceSecondPhone;

  /// No description provided for @deviceActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get deviceActive;

  /// No description provided for @devicePendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get devicePendingApproval;

  /// No description provided for @deviceUsageToday.
  ///
  /// In en, this message translates to:
  /// **'{usage} today'**
  String deviceUsageToday(String usage);

  /// No description provided for @deviceLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get deviceLimit;

  /// No description provided for @deviceDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get deviceDisconnect;

  /// No description provided for @onlyApprovedDevices.
  ///
  /// In en, this message translates to:
  /// **'Only approved devices may connect'**
  String get onlyApprovedDevices;

  /// No description provided for @pairingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection guide'**
  String get pairingTitle;

  /// No description provided for @pairStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Turn on the phone\'s hotspot'**
  String get pairStep1Title;

  /// No description provided for @pairStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Enable internet sharing in the phone\'s settings.'**
  String get pairStep1Body;

  /// No description provided for @pairStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Open Wi-Fi settings on the second device'**
  String get pairStep2Title;

  /// No description provided for @pairStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Connect it to that same hotspot.'**
  String get pairStep2Body;

  /// No description provided for @pairStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Set the proxy to Manual'**
  String get pairStep3Title;

  /// No description provided for @pairStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Enter the address and port below.'**
  String get pairStep3Body;

  /// No description provided for @pairStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Save, or scan the QR'**
  String get pairStep4Title;

  /// No description provided for @pairStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Once saved, its traffic goes through the tunnel.'**
  String get pairStep4Body;

  /// No description provided for @copyAddressPort.
  ///
  /// In en, this message translates to:
  /// **'Copy address and port'**
  String get copyAddressPort;

  /// No description provided for @splitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split tunneling'**
  String get splitTitle;

  /// No description provided for @splitBody.
  ///
  /// In en, this message translates to:
  /// **'Choose which apps go through the tunnel.'**
  String get splitBody;

  /// No description provided for @appBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get appBrowser;

  /// No description provided for @appMessenger.
  ///
  /// In en, this message translates to:
  /// **'Messenger'**
  String get appMessenger;

  /// No description provided for @appBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get appBank;

  /// No description provided for @appVideo.
  ///
  /// In en, this message translates to:
  /// **'Video streaming'**
  String get appVideo;

  /// No description provided for @routedThroughTunnel.
  ///
  /// In en, this message translates to:
  /// **'Goes through the tunnel'**
  String get routedThroughTunnel;

  /// No description provided for @routedDirect.
  ///
  /// In en, this message translates to:
  /// **'Connects directly'**
  String get routedDirect;

  /// No description provided for @allThroughTunnel.
  ///
  /// In en, this message translates to:
  /// **'All through tunnel'**
  String get allThroughTunnel;

  /// No description provided for @noneThroughTunnel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneThroughTunnel;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security and sync'**
  String get securityTitle;

  /// No description provided for @settingKillSwitch.
  ///
  /// In en, this message translates to:
  /// **'Cut internet if the tunnel drops'**
  String get settingKillSwitch;

  /// No description provided for @settingKillSwitchNote.
  ///
  /// In en, this message translates to:
  /// **'Kill switch'**
  String get settingKillSwitchNote;

  /// No description provided for @settingSecureDns.
  ///
  /// In en, this message translates to:
  /// **'Secure DNS'**
  String get settingSecureDns;

  /// No description provided for @settingSecureDnsNote.
  ///
  /// In en, this message translates to:
  /// **'1.1.1.1 · DoH'**
  String get settingSecureDnsNote;

  /// No description provided for @settingAutoConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect automatically at startup'**
  String get settingAutoConnect;

  /// No description provided for @settingAutoConnectNote.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get settingAutoConnectNote;

  /// No description provided for @settingSyncLists.
  ///
  /// In en, this message translates to:
  /// **'Sync lists between devices'**
  String get settingSyncLists;

  /// No description provided for @settingSyncListsNote.
  ///
  /// In en, this message translates to:
  /// **'Mobile and desktop'**
  String get settingSyncListsNote;

  /// No description provided for @connectionLog.
  ///
  /// In en, this message translates to:
  /// **'Connection log'**
  String get connectionLog;

  /// No description provided for @desktopNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get desktopNavDashboard;

  /// No description provided for @desktopNavShare.
  ///
  /// In en, this message translates to:
  /// **'Share connection'**
  String get desktopNavShare;

  /// No description provided for @desktopNavHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get desktopNavHistory;

  /// No description provided for @desktopNavSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple mode'**
  String get desktopNavSimple;

  /// No description provided for @desktopNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get desktopNavSettings;

  /// No description provided for @desktopConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected · {country}'**
  String desktopConnectedTo(String country);

  /// No description provided for @statHealthyConfigs.
  ///
  /// In en, this message translates to:
  /// **'Healthy configs'**
  String get statHealthyConfigs;

  /// No description provided for @statHealthyProxies.
  ///
  /// In en, this message translates to:
  /// **'Healthy proxies'**
  String get statHealthyProxies;

  /// No description provided for @statConnectedDevices.
  ///
  /// In en, this message translates to:
  /// **'Connected devices'**
  String get statConnectedDevices;

  /// No description provided for @statUsageToday.
  ///
  /// In en, this message translates to:
  /// **'Usage today'**
  String get statUsageToday;

  /// No description provided for @fastestOptions.
  ///
  /// In en, this message translates to:
  /// **'Fastest options'**
  String get fastestOptions;

  /// No description provided for @redoSetupShort.
  ///
  /// In en, this message translates to:
  /// **'Run setup again'**
  String get redoSetupShort;

  /// No description provided for @trayTitle.
  ///
  /// In en, this message translates to:
  /// **'Tray and quick tile'**
  String get trayTitle;

  /// No description provided for @traySwitchServer.
  ///
  /// In en, this message translates to:
  /// **'Switch server'**
  String get traySwitchServer;

  /// No description provided for @trayShareOn.
  ///
  /// In en, this message translates to:
  /// **'Share connection · on'**
  String get trayShareOn;

  /// No description provided for @trayExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get trayExit;

  /// No description provided for @tileShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tileShare;

  /// No description provided for @devicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} devices'**
  String devicesCount(int count);

  /// No description provided for @perPlatform.
  ///
  /// In en, this message translates to:
  /// **'On each platform'**
  String get perPlatform;

  /// No description provided for @surfaceAndroid.
  ///
  /// In en, this message translates to:
  /// **'Quick tile and widget'**
  String get surfaceAndroid;

  /// No description provided for @surfaceIos.
  ///
  /// In en, this message translates to:
  /// **'Shortcut and widget'**
  String get surfaceIos;

  /// No description provided for @surfaceWindows.
  ///
  /// In en, this message translates to:
  /// **'System tray'**
  String get surfaceWindows;

  /// No description provided for @surfaceMacos.
  ///
  /// In en, this message translates to:
  /// **'Menu bar'**
  String get surfaceMacos;

  /// No description provided for @surfaceLinux.
  ///
  /// In en, this message translates to:
  /// **'CLI and GUI'**
  String get surfaceLinux;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'PoPo — phase 0'**
  String get galleryTitle;

  /// No description provided for @gallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} screens, built from the design system\'s tokens. No network, no server — interface only.'**
  String gallerySubtitle(int count);

  /// No description provided for @runRealSearch.
  ///
  /// In en, this message translates to:
  /// **'Run a real search (01 → 02)'**
  String get runRealSearch;

  /// No description provided for @availAndroidDesktop.
  ///
  /// In en, this message translates to:
  /// **'Android and desktop'**
  String get availAndroidDesktop;

  /// No description provided for @availAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Android only'**
  String get availAndroidOnly;

  /// No description provided for @availDesktopOnly.
  ///
  /// In en, this message translates to:
  /// **'Desktop only'**
  String get availDesktopOnly;

  /// No description provided for @seeResults.
  ///
  /// In en, this message translates to:
  /// **'See {count} results'**
  String seeResults(int count);

  /// No description provided for @foundCount.
  ///
  /// In en, this message translates to:
  /// **'{count} found'**
  String foundCount(int count);

  /// No description provided for @notTestedYet.
  ///
  /// In en, this message translates to:
  /// **'Not tested yet — extraction and initial ranking only.'**
  String get notTestedYet;

  /// No description provided for @nothingFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was found. Enable more engines, or try again later.'**
  String get nothingFoundBody;

  /// No description provided for @sourcesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sources'**
  String sourcesCount(int count);

  /// No description provided for @screenSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get screenSearch;

  /// No description provided for @screenScanning.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get screenScanning;

  /// No description provided for @screenResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get screenResults;

  /// No description provided for @screenConfigDetail.
  ///
  /// In en, this message translates to:
  /// **'Config detail'**
  String get screenConfigDetail;

  /// No description provided for @screenSimpleStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get screenSimpleStart;

  /// No description provided for @screenSimpleSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get screenSimpleSteps;

  /// No description provided for @screenSimpleReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get screenSimpleReady;

  /// No description provided for @screenSimpleConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get screenSimpleConnected;

  /// No description provided for @screenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get screenSettings;

  /// No description provided for @screenSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get screenSaved;

  /// No description provided for @screenKeywords.
  ///
  /// In en, this message translates to:
  /// **'Search phrases'**
  String get screenKeywords;

  /// No description provided for @screenProxyDetail.
  ///
  /// In en, this message translates to:
  /// **'Proxy detail'**
  String get screenProxyDetail;

  /// No description provided for @screenHistory.
  ///
  /// In en, this message translates to:
  /// **'History and import'**
  String get screenHistory;

  /// No description provided for @screenErrors.
  ///
  /// In en, this message translates to:
  /// **'Empty and error'**
  String get screenErrors;

  /// No description provided for @screenOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get screenOnboarding;

  /// No description provided for @screenProxyServer.
  ///
  /// In en, this message translates to:
  /// **'Proxy server'**
  String get screenProxyServer;

  /// No description provided for @screenDevices.
  ///
  /// In en, this message translates to:
  /// **'Connected devices'**
  String get screenDevices;

  /// No description provided for @screenPairing.
  ///
  /// In en, this message translates to:
  /// **'Connection guide'**
  String get screenPairing;

  /// No description provided for @screenSplitTunnel.
  ///
  /// In en, this message translates to:
  /// **'Split tunneling'**
  String get screenSplitTunnel;

  /// No description provided for @screenSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security and sync'**
  String get screenSecurity;

  /// No description provided for @screenDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get screenDesktop;

  /// No description provided for @screenTray.
  ///
  /// In en, this message translates to:
  /// **'Tray and quick tile'**
  String get screenTray;

  /// No description provided for @runErrorNoEngines.
  ///
  /// In en, this message translates to:
  /// **'No engines are enabled.'**
  String get runErrorNoEngines;

  /// No description provided for @runErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'The search could not be completed.'**
  String get runErrorFailed;

  /// No description provided for @placeNlAmsterdam.
  ///
  /// In en, this message translates to:
  /// **'Netherlands · Amsterdam'**
  String get placeNlAmsterdam;

  /// No description provided for @placeDeFrankfurt.
  ///
  /// In en, this message translates to:
  /// **'Germany · Frankfurt'**
  String get placeDeFrankfurt;

  /// No description provided for @placeFiHelsinki.
  ///
  /// In en, this message translates to:
  /// **'Finland · Helsinki'**
  String get placeFiHelsinki;

  /// No description provided for @placePlWarsaw.
  ///
  /// In en, this message translates to:
  /// **'Poland · Warsaw'**
  String get placePlWarsaw;

  /// No description provided for @placeTrIstanbul.
  ///
  /// In en, this message translates to:
  /// **'Türkiye · Istanbul'**
  String get placeTrIstanbul;

  /// No description provided for @placeNl.
  ///
  /// In en, this message translates to:
  /// **'Netherlands'**
  String get placeNl;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow the device'**
  String get languageSystem;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'fa':
      return LFa();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
