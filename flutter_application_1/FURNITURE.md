# Furniture catalog

The existing home furniture tab now opens the complete catalog. Home product
previews open the same product details. `/furniture` also opens the listing.
The listing opens filters and receives a validated `FurnitureFilters` result;
back without applying leaves the previous selection unchanged. Product details
receive the selected `Furniture` directly. The existing bottom navigation is reused.

## Files

New:
- `lib/models/furniture.dart`: catalog product, filter and sort types.
- `lib/services/furniture_store.dart`: four sample records, shared session state,
  search/filter/sort logic, favorites and quantity-based cart.
- `lib/services/furniture_preview_service.dart`: injectable 3D/AR adapter interface
  and explicit unavailable implementation.
- `lib/screens/furniture_listing_screen.dart`
- `lib/screens/furniture_filter_screen.dart`
- `lib/screens/furniture_details_screen.dart`
- `lib/widgets/furniture_cart_button.dart`: shared count and editable local cart.
- `lib/widgets/furniture_navigation.dart`: existing navigation integration.
- `assets/images/catalog_chair.png`, `catalog_lamp.png`: artwork extracted from
  the supplied listing reference; no unrelated external imagery.
- `test/furniture_test.dart`: catalog, navigation, state and responsive checks.

Modified: `lib/main.dart` adds `/furniture`; `lib/screens/home_screen.dart` connects
the furniture tab, previews, favorites count and cart to shared state;
`lib/widgets/furniture_card.dart` displays actual company and model availability.
The existing AI result `DesignFurniture` remains separate: it describes generated
design line items, not the sample shopping catalog. Sample catalog items are not
claimed as products detected in an AI image.

## Run and test

Run `flutter run`, sign in using the existing flow and select **Тавилга**.
No backend is needed for this feature. Search, category chips, all filter controls,
sorting, favorites, gallery paging, cart additions/removals and totals work locally.
The sample products each have one real supplied image; the gallery supports more
images without inventing additional views. Counts derive from the current catalog
and search. Price limits are inclusive, dimensions are maximum centimeters,
multiple materials/colors match any selected value within that group, and groups
combine together. Empty dimension/upper-price fields mean unrestricted.

Filters, query, sort, favorites and cart survive navigation during the app session.
They are not persisted across app restarts and do not represent server orders.
There are four sample products, so the UI intentionally does not show the reference's
static count of 24. Sample company links open a clearly labelled company placeholder.

Run `flutter analyze` and `flutter test`. Furniture tests cover combined filters,
case-insensitive search, sorting, cart quantities and total, favorite synchronization,
detail navigation, validation and resetting filters, missing 3D dialog, and all
three screens at 320px with normal and enlarged text.

## Future integration

No compatible `.glb`/`.gltf` models were found. All sample records accurately report
no 3D model. The 3D and AR actions show explicit Mongolian unavailable dialogs.
Inject a platform implementation of `FurniturePreviewService` once compatible
models and a real viewer/placement engine are available; no simulated AR is used.
Company profiles, checkout, catalog backend and durable per-user shopping state
remain future work. No new dependencies were introduced. Existing camera, room
upload, segmentation, generation, project saving and backend code are retained.
