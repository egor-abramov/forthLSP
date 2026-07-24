# Forth LSP Plugin
Плагин для анализа кода и подсветки синтакиса моей [реализации Forth'a](https://github.com/egor-abramov/forth). Forth LSP предназначет для Intellij Platform, которая используется ide от JetBrains.

## Возможности
Плагин поддерживает подсветку синтаксиса и статический анализ кода.

**Анализ включает**
* Рассчет глубины стека
* Проверка контрактов
* Проверка существования процедур
* Проверка импортов
* Проверка условий и циклов

Подробнее про устройство языка смотреть [тут](https://github.com/egor-abramov/forth).

## Установка
Установите архив с плагинов из раздела [Actions](https://github.com/egor-abramov/forthLSP/actions). Далее в ide передйтие в `File -> Settings -> Plugins -> Install Plugin From Disk`. Плагин является платформонезависимым, поэтому все ОС могут использовать один архив.

## Реализация
Плагин состоит из клиента и сервера, взаимодействуюжих по `LSP` (Language Server Protocol).

### Клиент
Клиентская часть реализована на `Java` и состоит из:
* LSP-клиент -- отправляет запросы серверу
* Анализатор синтаксиса -- реализует подсветку синтаксиса

Код находится [тут](https://github.com/egor-abramov/forthLSP/tree/main/src/main/java).

### Сервер
Реализован на `Hskell` и состоит из:
* Парсер
* Анализатор
* Загрузчик библиотек

Код нахожится [тут](https://github.com/egor-abramov/forthLSP/tree/main/server).

## Локальный запуск
**Локальное ide**
```shell
    git clone https://github.com/egor-abramov/forthLSP.git
    ./gradlew runIde
```
**Локальная сборка**
```shell
    git clone https://github.com/egor-abramov/forthLSP.git
    ./gradlew buildPlugin
```

## Тестирование
Сервер покрыт e2e тестами, для клиента тестов нет, ибо лень.

Код тестов [тут](https://github.com/egor-abramov/forthLSP/tree/main/server/test).

Тестовые сценарии [тут](https://github.com/egor-abramov/forthLSP/tree/main/server/test/golden).

**Запуск** 
```shell
    cabal build all
    cabal test
```

**Обновление тестов**
```shell
    cabal build all
    cabal test --test-options="--accept"
```