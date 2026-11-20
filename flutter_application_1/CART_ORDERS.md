# Shopping cart and order requests

## Files

Created:
- `lib/screens/shopping_cart_screen.dart`
- `lib/screens/order_request_screen.dart`
- `lib/models/order_request.dart` (CartItem and OrderRequest)
- `lib/services/order_request_service.dart`
- `lib/widgets/cart_product_row.dart`
- `test/cart_order_test.dart`

Modified:
- `lib/services/furniture_store.dart`: persisted cart quantities, integer price
  snapshots, company IDs, explicit deletion, storage errors and serialized writes.
- `lib/models/furniture.dart`: company ID alongside the existing company name.
- `lib/widgets/furniture_cart_button.dart`: opens the full cart screen everywhere.
- `lib/main.dart`: restores the shared cart before starting the app.
- `lib/screens/placement_editor_screen.dart`: selected furniture opens details,
  where it can be added to the shared cart.
- `test/furniture_test.dart`: initializes mock persistence for existing cart tests.

## Working behavior

Home/catalog/product cart controls all open **Миний сагс**. Products are grouped by
company. Add/decrement/delete update all counts and totals. Decrement stops at one;
only the delete action removes an item. Catalog removals remain visible and can
be deleted, but cannot be included in a request. Empty carts link to the catalog.

Cart records persist in SharedPreferences as structured JSON with product ID,
company ID, quantity and integer unit-price snapshot. Totals are computed, never
stored as mutable cart state. Existing price snapshots remain until an item is
removed; a backend must eventually validate current prices before acceptance.
Sample catalog company IDs match the existing company directory. Other legacy
products without an ID receive an explicit local-only company key.

Each company has its own request action and form. A request includes only that
company's items. Name, Mongolian phone, city/district and address are required;
email is optional and validated if present. Phone input accepts eight digits
starting with 5–9 and optional +976, spaces and hyphens. Other regions use
**Орон нутаг**, with the full locality entered in the address. Quantity-aware
summaries update with shared cart state. Successful receipt data is frozen.

The submit guard prevents duplicate taps while saving. The same request ID is
reused on retry; local draft persistence replaces that ID rather than duplicating
it. A failed write leaves the form available for retry. Saving a local request
does not clear the cart. Contact data is stored locally in app preferences.

## Local-only submission

No order endpoint or real company-facing delivery service exists in the inspected
FastAPI backend. `LocalOrderRequestService` persists drafts, including price
snapshots, UTC timestamp and **Хүлээгдэж байна** status with
`delivery_status: local_draft`. It returns `RequestDelivery.localDraft`.
The screen explicitly says **Хүсэлт түр хадгалагдлаа. Компанид илгээгдээгүй.**
Drafts are available through `LocalOrderRequestService.drafts()`; there is no
separate order-history/draft browser in this scope.

`OrderRequestService` is the integration boundary for future FastAPI submission.
A real adapter must provide authenticated company routing, server validation,
idempotency and explicit acceptance before returning `delivered`. Backend order
history and draft synchronization remain unimplemented. No online payments,
inventory claims, shipping charges or real company integration were added.

## Run and test

Run `flutter run` with the existing setup. No backend is needed for cart/drafts.
Add products in furniture details, open the cart, change quantities, delete, and
restart to check persistence. Add a chair and sofa to check separate company
requests. Submit empty/invalid forms, then fill a valid form and confirm the
local-only message. Existing saved-project furniture and company catalog paths
lead to the same details/cart flow.

Run `flutter analyze --no-pub` and `flutter test --no-pub`. Tests cover persistence
reload, price snapshots, quantity floors/deletion, mixed-company rejection,
request isolation, local draft persistence, validation, failure/retry availability,
duplicate-submit guard, 320px layouts, enlarged text and keyboard insets.
Native device restart and visual comparison remain useful manual checks.
