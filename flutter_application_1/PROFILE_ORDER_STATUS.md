# Profile and order tracking

Implemented from `references/Профайл.png` and `references/Хүсэлтийн төлөв.png`
using the existing theme, layout and bottom navigation. No sample identity,
reference number, company confirmation or arrival estimate is shown as real data.

## Files

Created:
- `lib/screens/profile_screen.dart`: profile, real local counts, latest request,
  menu, explicit unavailable logout, current application version label.
- `lib/screens/profile_tools_screen.dart`: profile editing, existing favorites
  integration, local tips preference and privacy explanation.
- `lib/screens/order_status_screen.dart`: status, timeline, snapshot products,
  total and company contact integration.
- `lib/screens/order_history_screen.dart`: persisted request history.
- `lib/widgets/profile_navigation.dart`: existing navigation with profile selected.
- `test/profile_status_test.dart`.

Modified:
- `lib/models/order_request.dart`: explicit draft status, delivery provenance,
  Mongolian labels and timeline mapping; existing JSON remains readable.
- `lib/services/order_request_service.dart`: normalizes every local save as a draft
  and refreshes a shared history notifier after persistence.
- `lib/services/auth_service.dart`: observable preview identity and locally persisted
  profile fields, scoped by the entered login identifier (or local guest profile).
- `lib/screens/home_screen.dart`: profile tab integration.
- `lib/screens/order_request_screen.dart`: saved-result link to the request status.
- `lib/screens/placement_editor_screen.dart`: applies the local tips preference.
- `test/widget_test.dart`: mock profile persistence in existing authentication tests.

## Run and test

Run `flutter run` with the existing configuration. No backend is needed for these
local screens. Add furniture, open the cart, fill the request form and save it.
The result explicitly says it was not sent. Tap **Хүсэлтийн төлөв харах**, then
**Миний захиалгууд**, and reopen the record. Open the profile tab to see the same
newest request, dynamic counts, favorites and company directory.

Edit a profile name/email/phone, save, and reopen editing. Values persist locally;
sign in with the same preview identifier after restart to use that local profile.
The existing preview identity itself is not a persistent authenticated session.
Favorites reuse existing session state. Statistics count actual local saved
projects and request records; they do not pretend to be a remote account aggregate.
Enable/disable placement tips under **Тохиргоо, нууцлал**, then reopen the editor.

Run `flutter analyze --no-pub` and `flutter test --no-pub`. Tests cover draft
provenance, all timeline status mappings, history refresh, local record reload,
profile/recent/history/status navigation, totals with quantities, profile editing,
favorite removal and 320px screens at enlarged text size. Existing account,
camera, upload, AI, project, furniture and cart regression tests also run.
Device dialer behavior still requires device testing with configured contact data.

## Truthful statuses and remaining integration

The current FastAPI backend has no company order submission/status API. Every
local submission is normalized to `draft` with `delivery_status: local_draft`,
even if a caller mistakenly supplies a later status. Older local records with
**Хүлээгдэж байна** are displayed as drafts. No timeline stage is marked complete
for a draft. Explicit backend-provenance statuses support submitted, reviewing,
confirmed, delivering, delivered, cancelled and rejected. Cancelled/rejected or
unknown states do not invent a completed stage history. There is no automatic
status advancement or fixed company response estimate.

Future backend work: authenticated per-user profiles, authenticated request
submission, company acceptance/status history and remote synchronization. A real
adapter must persist the server-accepted record and delivery provenance before
linking to status/history. Current history is device-local, not a secure multiuser
account database. No real delivered requests are seeded or fabricated.

Authentication remains the existing preview flow, not a server session. Therefore
logout is explicitly disabled, as requested when authentication is unavailable;
there is no false successful logout or unrelated data clearing. Notifications
are an explicit empty/unavailable screen. No support contacts were configured,
so help explains that rather than inventing them. Demo company records retain
their existing identity and no contact number is invented; the dialer action is
enabled only for a configured valid number. Footer 1.0 matches the current
`pubspec.yaml` release version 1.0.0+1. No new dependency was needed.
