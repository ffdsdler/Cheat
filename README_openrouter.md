# Cheat — Neural image generation integration (OpenRouter)

В этой ветке добавлена экспериментальная интеграция с OpenRouter (модель `openrouter/free`) для генерации изображений и клиентского меню в игре.

Важно: API-ключ не включён в репозиторий. Надёжно храните ключ в `ServerScriptService/OpenRouterConfig.lua` (см. ниже) и не публикуйте его.

Что добавлено
- server/OpenRouterConfig.lua — конфиг (заполните API_KEY).
- server/OpenRouterModule.lua — модуль для вызова OpenRouter API (черновик).
- server/OpenRouterHandler.lua — серверный обработчик RemoteEvent для безопасных запросов.
- client/OpenRouterClient.lua — клиентский LocalScript, создаёт простое меню UI и показывает изображения.

Как это работает (вкратце)
1. Клиент открывает меню и отправляет промпт для генерации изображения на сервер через RemoteEvent.
2. Сервер (безопасно) использует API-ключ и вызывает OpenRouter API через HttpService.
3. Сервер получает ответ (URL на изображение) и пересылает его клиенту.
4. Клиент отображает изображение в ImageLabel.

Настройка (обязательно для работы)
1. Включите HTTP Requests в настройках игры (Game Settings → Security → Allow HTTP Requests).
2. Создайте `ServerScriptService/OpenRouterConfig.lua` и заполните API_KEY и при необходимости BASE_URL/ENDPOINT.

Пример содержимого server/OpenRouterConfig.lua (заполните своими значениями):
```lua
return {
  API_KEY = "REPLACE_WITH_YOUR_KEY",
  BASE_URL = "https://openrouter.ai",
  IMAGE_ENDPOINT = "/v1/images/generate", -- проверьте в документации OpenRouter для правильного пути
  MODEL = "openrouter/free",
}
```

Ограничения и безопасность
- Никогда не храните API-ключ в client-side коде (StarterPlayerScripts). Храните в ServerScriptService.
- OpenRouter может возвращать либо URL либо raw/base64 — текущая реализация ожидает URL в ответе.
- Учтите квоты, задержки и стоимость запросов к API.

Дальше можно улучшить:
- Кэшировать изображения на сервере (если OpenRouter даёт base64 — загрузить в CDN/Asset и вернуть ссылку).
- Добавить галерею сохранённых изображений.
- Поддержать дополнительные опции (стили, семплы, размеры).

