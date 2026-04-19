# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                         # Install dependencies
flutter pub run build_runner build      # Regenerate Riverpod/JSON code after model changes
flutter run                             # Run app (pick device)
flutter analyze                         # Lint
flutter test                            # Run all tests
flutter test test/path/to/test.dart     # Run single test
flutter build apk                       # Android release build
```

> Run `build_runner` whenever you modify files with `@riverpod` annotations or `@JsonSerializable` models.

## Architecture

PeraCo is a Flutter marketplace agrícola colombiano. Backend es **Supabase** (PostgreSQL + Auth) corriendo localmente via Docker, expuesto con ngrok — la URL en `.env` puede cambiar cuando se reinicia ngrok. Estado: **Riverpod** (annotation-based con code generation). Navegación: **GoRouter**. Fuente global: **Poppins**.

### Brand colors

| Token | Hex | Uso |
|-------|-----|-----|
| lima | `#9CC200` | Acción primaria, CTAs |
| verde | `#1B8F31` | Secundario |
| verde oscuro | `#16502D` | Headers, énfasis |

### Three user roles

| Rol (en código) | Nombre UX | Descripción |
|-----------------|-----------|-------------|
| `client` | Cliente | B2C y B2B — catálogo, carrito, checkout, tracking |
| `farmer` | Vendedor | Productor o Comerciante — productos, inventario, cosechas, pedidos |
| `driver` | PeraGoger | Repartidor — entregas, mapa, historial |

Role is stored in Supabase and drives routing — GoRouter redirects to the role-appropriate shell after auth.

### Directory structure

```
lib/
  core/
    config/         # Supabase initialization (reads .env via flutter_dotenv)
    constants/      # Colors, text styles, app-wide constants
    router/         # GoRouter config with role-based redirect logic
    theme/          # Material Design 3 theme
    utils/          # Formatters (Colombian Spanish / COP currency via intl)
  features/
    auth/           # Login + signup screens (shared, role-selected at signup)
    admin/          # Admin dashboard
    client/         # Client shell: home, catalog, product, cart, checkout, orders, tracking
    farmer/         # Farmer shell: dashboard, products, harvests, orders
    driver/         # Driver shell: deliveries, map, history
    profile/        # Shared profile screen (avatar, addresses, settings)
  shared/
    widgets/        # Role-specific scaffolds (client/farmer/driver_scaffold.dart) + shared widgets
    models/         # Shared data models
    providers/      # Shared Riverpod providers
  main.dart         # Entry: loads .env → initializes Supabase → ProviderScope → MaterialApp
```

### Key patterns

- Each feature folder typically has `screens/`, `widgets/`, and `providers/` subdirectories.
- Providers use `@riverpod` annotations; generated files end in `.g.dart` (do not edit manually).
- Role-specific scaffolds (`ClientScaffold`, `FarmerScaffold`, `DriverScaffold`) wrap each role's navigation shell.
- Supabase client is accessed via `Supabase.instance.client` throughout the app.
- Images use `cached_network_image`; uploads use `image_picker`.
- Maps/location use `flutter_map` + `geolocator`.

### Environment

Supabase credentials live in `.env` at the project root:
```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```
The `.env` file is loaded via `flutter_dotenv` before any Riverpod initialization in `main.dart`.
