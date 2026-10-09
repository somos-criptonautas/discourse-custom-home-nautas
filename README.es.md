# Custom Home Nautas

[ENGLISH](README.md) | **ESPAÑOL**

Mantenido por Criptonautas. Sin afiliación ni respaldo de Discourse (Civilized Discourse Construction Kit, Inc.).

Componente de tema de Discourse con bloques de página de inicio al estilo de Meta. Adaptado de
[discourse/discourse-theme-skills](https://github.com/discourse/discourse-theme-skills).

## Dónde vive

El modificador `custom_homepage` le da a Discourse una ruta de inicio personalizada:

- Configúrala como página de inicio del sitio y se sirve en **`/`**.
- Deja **Últimos** como vista por defecto y sigue disponible en **`/custom`**.

La ruta es del núcleo, así que un tema no puede moverla (por ejemplo a `/home`): una visita directa a
cualquier otra ruta llega al router del servidor de Discourse, que solo conoce `/custom`.

## Bloques

- **Hero**: título, subtítulo, icono opcional (`hero_icon`) e imagen (`hero_image`,
  junto al texto en pantallas anchas, encima en las estrechas). Los visitantes sin sesión
  siempre lo ven, con un botón "Empezar" a `/signup`; los miembros con sesión
  lo ven solo si están en un grupo elegido en `hero_groups`, así que puede funcionar como
  banner para miembros nuevos.
- **Temas destacados**: carrusel horizontal de tarjetas (CSS scroll-snap, sin JS). Se muestra
  solo cuando `featured_topics_tags` o `featured_topics_categories` está configurado. Los miembros
  eligen la fuente en un desplegable y la elección se recuerda por navegador;
  los visitantes sin sesión siempre ven la primera. Las categorías a las que el usuario no
  tiene acceso se descartan. Las tarjetas muestran el **resumen de IA** del tema en lugar del extracto
  cuando existe, salvo que el usuario haya elegido Compacto o Extractos en el
  botón de extractos/resúmenes.
- **Lista de temas**: una sola lista, que se cambia desde un desplegable entre *Últimos*,
  *Tendencia* (`hot`) y *Lo mejor* de la semana, el mes o de siempre (`top` con un
  periodo), abre en `topics_default_view` y se recuerda por navegador. Solo Top
  usa periodo: Últimos ordena por actividad reciente y Hot aplica su propio decaimiento a
  la puntuación. Vuelve a Últimos cuando la vista elegida está vacía, como pasa con Hot
  hasta que Discourse puntúa los temas. Pide el doble de `featured_list_count` de una
  vez (dos páginas de entrada, así cada vista abre con el doble de temas) y nunca
  añade más al hacer scroll: el enlace "ver todo" hace el resto.
  Usa las tarjetas de tema de Horizon cuando está asociado a él, así que muestra los resúmenes de IA
  donde los muestre la lista de temas (`featured_list_count`).
- **Ranking**: karma semanal, mensual o total, desde un desplegable y
  recordado por navegador. Muestra tu propia posición cuando estás fuera del top
  `leaderboard_count`. Requiere `discourse_gamification_enabled`.
- **Próximos eventos**: de los eventos de post de discourse-calendar. Requiere
  `calendar_enabled`.
- **Llamado a registrarse**: para visitantes sin sesión (`cta_link`, `cta_icon`).
- **Estilo de tarjeta para la barra lateral derecha**, para que
  [discourse-right-sidebar-blocks](https://github.com/discourse/discourse-right-sidebar-blocks)
  combine con la página de inicio.

## Resúmenes de IA

Los resúmenes solo aparecen a quienes discourse-ai permite verlos: `ai_summary_gists_enabled`
activado y el agente de `ai_summary_gists_agent` permitiendo el grupo del usuario (`everyone`
para incluir a visitantes sin sesión). Si no, las tarjetas usan el extracto.

## Instalación

Súbelo en **Admin > Personalizar > Temas** y asócialo a tu tema activo. Luego
configura la página personalizada como inicio, o deja Últimos por defecto y enlaza a
`/custom`.

## Licencia

MIT (upstream: Civilized Discourse Construction Kit, Inc.). Modificaciones © 2026 Criptonautas. Consulta [LICENSE](LICENSE).

Texto de este README bajo [CC BY-NC-SA 4.0](CC-BY-NC-SA-4.0.txt).
