# Cero

App para controlar deudas y salir de ellas, poco a poco. Hecha por A. Uribe.
Para tres personas: cada deuda tiene dueño y las cuotas se reparten según el sueldo de cada uno.

## Estado (versión 0.1)
- Pantallas: Arranque, Hoy, Deudas, Detalle, Agregar deuda, Pagos, Plan, Ingresos, Ajustes. Oscuro y claro.
- Cálculo: simulador mes a mes, estrategias "más intereses primero" y "la más chica primero",
  la cuota de la deuda que termina pasa a la siguiente, y "cuánto extra necesito para terminar en X meses".
- Datos de ejemplo. Todavía no se guardan al cerrar la app.

## Falta
1. Guardar datos en el teléfono.
2. Cuentas y sincronización entre los tres iPhones (Firebase).
3. Avisos de pago en el teléfono.
4. Cuenta de Apple Developer (US$99 al año) y TestFlight.

## Cómo se compila sin Mac
- Cada cambio que subas a GitHub corre el análisis y las pruebas (`.github/workflows/revisar.yml`).
- `codemagic.yaml` compila un APK de Android de prueba gratis y, con la cuenta de Apple, el IPA para TestFlight.
- Las carpetas `ios/` y `android/` las genera `flutter create` en la compilación.
