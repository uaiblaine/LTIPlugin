# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-06-18

Modernisation release: PHP 8 support, Composer-managed LTI library, and
verified compatibility with LimeSurvey 7.

### [Dependency]

- Migrated the LTI Tool Provider library from a git submodule
  (`adamzammit/LTI-Tool-Provider-Library-PHP` @ `488d5de`) to a Composer
  dependency: **`izumi-kun/lti` `^1.2.1`** (PHP 8 compatible). The PSR-4
  namespace is unchanged (`IMSGlobal\LTI\`), so no `use` statements needed to
  change.
- Removed the `LTI-Tool-Provider-Library-PHP` submodule and the now-empty
  `.gitmodules`.
- Added `composer.json` / `composer.lock`. The dependency installs to
  `vendor/`, which is `.gitignore`d and bundled into release packages.
- Updated the bootstrap include from
  `require_once __DIR__ . '/LTI-Tool-Provider-Library-PHP/vendor/autoload.php'`
  to `require_once __DIR__ . '/vendor/autoload.php'`.

### [Bug Fix]

- **`newDirectRequest()` TypeError on PHP 8.** Every `$this->get(...)` call
  passed the whole setting-definition *array* as the default value instead of
  the default *string*, e.g.
  `$this->get('sUrlAttribute', null, null, $this->settings['sUrlAttribute'])`.
  When the setting was not stored, `get()` returned the array and the
  subsequent `isset($params[$urlAttribute])` raised
  `TypeError: Cannot access offset of type array in isset or empty`. Fixed all
  nine affected settings by passing `...['default']`: `sUrlAttribute`,
  `sResourceIdAttribute`, `sUserIdAttribute`, `sFirstNameAttribute`,
  `sLastNameAttribute`, `sEmailAttribute`, `sCourseTitleAttribute`,
  `sResultSourceAttribute`, `sOutcomeServiceURLAttribute`.
- **Grade/result return broken by the library migration.** In `izumi-kun/lti`
  `1.2.1`, `ResourceLink::$consumer` is declared `private` (it was `protected`
  in the old submodule). The plugin's `LTIResourceLink::setConsumer()` wrote to
  `$this->consumer`, which under a `private` parent property silently targets a
  separate child-scoped property — so the parent's `getConsumer()` never saw
  the consumer and the outcome request crashed with
  `Call to a member function loadToolConsumer() on null`. Fixed by holding the
  injected consumer in an explicit `private $ltiConsumer` and **overriding
  `getConsumer()`** to return it (also avoids the PHP 8.2 "dynamic property"
  deprecation).
- **Debug mode could turn itself on.** `debug()` passed
  `$this->settings['bDebugMode']` (a truthy array) as the default, so an unset
  value enabled debug output. Now passes `['default']`.

### [PHP 8.3 Compat]

- `handleRequest()` now reads `$_REQUEST['lti_message_type']` /
  `$_REQUEST['lti_version']` via the null-coalescing operator to avoid
  "Undefined array key" warnings on missing keys.
- `ArrayOAuthDataStore::lookup_consumer()` now guards the lookup with
  `!empty(...)` instead of reading a possibly-undefined array key.
- Audited both `LTIPlugin.php` and `ArrayOAuthDataStore.php` for other PHP 8.x
  breakages — no `${var}` interpolation, no `$str{0}` offsets, no `each()` or
  other removed functions, no optional-before-required parameters, and no
  loose comparisons whose behaviour changed.

### [LimeSurvey 7 Compat]

- Audited the plugin against the LimeSurvey **7.0.4** source. **No code changes
  were required** — LimeSurvey 7 still runs on **Yii 1.1.26** (no Yii 2
  migration), so no architectural rework is needed. Verified against the real
  source:
  - All subscribed events still exist with identical payloads:
    `newDirectRequest` / `newUnsecureRequest` (`target`, `function`),
    `beforeSurveySettings` (`survey`), `newSurveySettings`
    (`settings`, `survey`), `afterSurveyComplete` (`surveyId`, `responseId`).
  - `Survey::model()->findByPk()`, `$survey->responsesTableName`,
    `$survey->tokenAttributes` unchanged.
  - `Token::model($sid)`, `countByAttributes()`, `findByAttributes()`,
    `findByToken()`, `Token::create($sid)`, `save()`, `generateToken()`,
    `setAttributes()`, and the `completed` default of `'N'` unchanged.
  - `Yii::app()->createAbsoluteUrl()`,
    `Yii::app()->getController()->redirect()`,
    `Yii::app()->securityManager->generateRandomString()` unchanged (Yii 1).
  - Global `tableExists()` helper still available.
  - `LimeExpressionManager::ProcessString()` still accepts the 8-argument
    signature the plugin uses.
  - `$this->api->getResponse($surveyId, $responseId)` unchanged.
- Updated `config.xml`: version bumped to **2.0.0** and the
  `<compatibility>` list set to **6.0** and **7.0** (the PHP 8 era LimeSurvey
  majors). The earlier 3.0/4.0/5.0 entries were dropped because this release
  requires PHP 8.0+.
