# Создаем временную папку
mkdir tmp

# Временный composer.json только с одной целью - установить sail
echo '{
    "name": "laravel/tmp",
    "require-dev": {
        "laravel/sail": "^1.14"
    },
    "require": {}
}
' > ./tmp/composer.json

docker run --rm \
    -v "$(pwd)/tmp":/opt \
    -w /opt \
    laravelsail/php80-composer:latest \
    bash -c "composer install"

sudo chmod -R 777 ./
# Удаляем существующий vendor
rm -Rf ./vendor

# Копируем зависимости для sail в основной vendor
mv ./tmp/vendor ./vendor

# Чистим за собой
rm -R ./tmp

# Копируем env, если нет такого
cp -n ./.env.example ./.env

# Запускаем ./sail
./vendor/bin/sail up -d

## Ставим остальные завимости
./vendor/bin/sail composer install

# Перезагружаем sail
./vendor/bin/sail down -v
./vendor/bin/sail up -d

# Генерируем ключ приложения
./vendor/bin/sail artisan key:generate

# Даем права на запись в storage
sudo chmod -R 777 ./storage

./vendor/bin/sail artisan storage:link

# Мигрируем
./vendor/bin/sail artisan migrate --seed
