# Projects and furniture companies

Implemented inside the existing Flutter application, using the three supplied
references and existing colors, shared layout, buttons and bottom navigation.

## Files

Created:
- `lib/screens/project_details_screen.dart`
- `lib/screens/placement_editor_screen.dart`
- `lib/screens/furniture_companies_screen.dart`
- `lib/screens/remote_projects_screen.dart` (preserves the former backend list)
- `lib/services/project_store.dart`
- `lib/services/project_image_cleanup.dart` and `_io.dart`
- `lib/widgets/project_image.dart`, `project_navigation.dart`
- `lib/models/furniture_company.dart`
- `test/projects_companies_test.dart`

Modified:
- `lib/screens/projects_screen.dart`: persistent local cards, count, saved filter,
  create, rename, confirmed delete, and backend-project access.
- `lib/models/room_design_project.dart`: extends the existing saved-project model
  with original/background/final paths, timestamps and placed instances.
- `lib/screens/ai_result_screen.dart`: stores a local copy after backend save.
- `lib/screens/ai_interior_screen.dart`: manual placement entry using the actual
  current working image, including a cleaned room when removal has completed.
- `lib/screens/home_screen.dart`: projects tab opens the real project screen.
- `lib/screens/furniture_details_screen.dart`, `furniture_listing_screen.dart`:
  company navigation.
- `pubspec.yaml`, `pubspec.lock`: url_launcher for future valid phone records.

## Test the flow

1. Run `flutter run` on Android/iOS. Use the existing backend launch configuration
   for AI processing; local placement does not require generation.
2. Upload/confirm a room and select preferences. In the existing editing screen,
   optionally remove furniture through the backend, then choose **Тавилгыг гараар
   байрлуулах**. The actual working image becomes the editable background.
3. Add furniture chips, drag instances, adjust scale/rotation, bring an instance
   forward or remove it. Save captures a final preview while keeping background
   and transforms separately. This is explicitly a 2D image collage, not AR/3D.
4. Open **Миний төсөл**, then the saved card. Check prices, rename and reopen the
   placement editor. Restart the app and confirm positions remain. Delete through
   the three-dot menu and confirmation dialog.
5. AI results saved through **Төслөө хадгалах** also create local records. Older
   backend projects can be imported by opening **Серверт хадгалсан төслүүд**.
6. Open **Тавилгын компаниуд** from the catalog or a product's company link.
   Search name/location, choose district chips, and open the company's products.
7. Use **Зургаар илгээх / хадгалах** in project details. Existing sharing exports
   through the device share sheet on mobile and save dialog on desktop. Platform
   share sheets and phone dialing need manual device testing.

## Persistence and boundaries

SharedPreferences contains JSON metadata only, never project image bytes. Images
use the existing private native application-support storage. Replaced/deleted
owned final previews are removed only when no project references them; originals
and backgrounds are retained because drafts and other projects may share them.
Cleanup failures retain the image safely. Project metadata includes server image
identifiers separately from local file paths. Manual placement totals sum actual
catalog products per instance. AI-image furniture is not invented or automatically
associated with sample catalog products.

Rename/delete and placements are local; the current API has no project update,
placement synchronization or deletion endpoint. Deleting locally does not delete
the cloud project. Public links are not supported or displayed. Native local image
persistence is implemented; browser projects retain the existing server workflow,
and browser local placement saving reports that it is unsupported.

Company records are demonstrations, not verified businesses. No verified badges
or example phone numbers are presented as real contacts. Valid future phone data
is validated and sent to the native `tel:` launcher; the current sample records
show a disabled missing-number control. Company product counts derive from the
four existing sample catalog products. The existing catalog keys companies by
name; stable company-ID catalog relationships remain a backend migration task.

Project positions, scale, rotation, layer order and unique instance identifiers
are preserved. No real AR, model renderer, checkout or secure public-share service
was introduced. The catalog's product photos retain their original backgrounds;
transparent product cutouts would improve the 2D collage.

## Verification

Run `flutter analyze --no-pub` and `flutter test --no-pub` after dependency resolution.
Automated tests cover metadata reload, transform round trip, rename/delete,
correct detail selection, actual catalog totals, placement reopening, company
search/empty results and company filtering. New screens are exercised at 320px
with enlarged text (missing-project state for the narrow details check).
Full native capture/save/export and device dialer still need device verification.

Dependency download completed, but Windows reported missing symlink support when
configuring desktop plugins. Enable Windows Developer Mode before building the
Windows desktop app; Android/iOS remain the intended targets. No system settings
were changed automatically.
