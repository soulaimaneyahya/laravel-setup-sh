#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Please provide a project name."
    exit 1
fi

project_name="$1"

# Step 1: Prerequisites
# Make sure PHP and Composer are installed

# Step 2: Install Laravel
composer create-project --prefer-dist --no-interaction --no-progress laravel/laravel $project_name

# Step 3: Install Laravel UI and dependencies
cd $project_name
echo "# $project_name" > README.md

composer require laravel/ui inertiajs/inertia-laravel
npm install

php artisan ui bootstrap --quiet
php artisan ui vue --quiet

# Step 4: Install Inertia.js and Vite dependencies
npm install @inertiajs/inertia @inertiajs/inertia-vue3 vue @vitejs/plugin-vue laravel-vite-plugin --save-dev

php artisan inertia:middleware

# Step 5: Configure Laravel for Inertia.js
# Step 6: Update Routes and Views
cat <<EOT > app/Http/Kernel.php
<?php

namespace App\Http;

use Illuminate\Foundation\Http\Kernel as HttpKernel;

class Kernel extends HttpKernel
{
    protected \$middleware = [
        \App\Http\Middleware\TrustProxies::class,
        \Illuminate\Http\Middleware\HandleCors::class,
        \App\Http\Middleware\PreventRequestsDuringMaintenance::class,
        \Illuminate\Foundation\Http\Middleware\ValidatePostSize::class,
        \App\Http\Middleware\TrimStrings::class,
        \Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull::class,
    ];

    protected \$middlewareGroups = [
        'web' => [
            \App\Http\Middleware\EncryptCookies::class,
            \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class,
            \Illuminate\Session\Middleware\StartSession::class,
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
            \App\Http\Middleware\VerifyCsrfToken::class,
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
            \App\Http\Middleware\HandleInertiaRequests::class,
        ],

        'api' => [
            \Illuminate\Routing\Middleware\ThrottleRequests::class.':api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],
    ];

    protected \$middlewareAliases = [
        'auth' => \App\Http\Middleware\Authenticate::class,
        'auth.basic' => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
        'auth.session' => \Illuminate\Session\Middleware\AuthenticateSession::class,
        'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can' => \Illuminate\Auth\Middleware\Authorize::class,
        'guest' => \App\Http\Middleware\RedirectIfAuthenticated::class,
        'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
        'signed' => \App\Http\Middleware\ValidateSignature::class,
        'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
    ];
}
EOT

# Step 6: Update Routes and Views
cat <<EOT > routes/web.php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\IndexController;

Route::get('/', [IndexController::class, 'index']);
Route::get('/show', [IndexController::class, 'show']);
EOT

php artisan make:controller IndexController
cat <<EOT > app/Http/Controllers/IndexController.php
<?php

namespace App\Http\Controllers;

class IndexController extends Controller
{
    public function index()
    {
        return inertia('Index/Index');
    }

    public function show()
    {
        return inertia('Index/Show');
    }
}
EOT

# Step 7: Create Inertia Views

rm resources/views/welcome.blade.php
rm -rf resources/js/components

cat <<EOT > resources/views/app.blade.php
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>{{ config('app.name') }}</title>

    @vite(['resources/sass/app.scss', 'resources/js/app.js'])
    @inertiaHead
</head>

<body>
    @inertia
</body>

</html>
EOT

mkdir -p resources/js/Layouts
cat <<EOT > resources/js/Layouts/Main.vue
<template>
    <Link href="/">Main Page</Link>&nbsp;
    <Link href="/show">Show Page</Link>
    <slot>Default</slot>
</template>
  
<script setup>
import { Link } from '@inertiajs/inertia-vue3'
</script>
EOT

mkdir -p resources/js/Pages/Index
cat <<EOT > resources/js/Pages/Index/Index.vue
<template>
    <main>
        <h3 class="mb-2 fw-bold">Home Page</h3>
        <p>Lorem ipsum dolor sit, amet consectetur adipisicing elit. Hic, nesciunt omnis accusamus et quisquam suscipit
            consectetur dicta non doloremque cum veritatis corrupti eveniet amet magnam, sed, obcaecati iure porro. Earum
            qui
            vitae expedita libero saepe voluptatem ab corporis suscipit rerum fugiat nam itaque deserunt incidunt quos
            optio,
            labore provident nisi.</p>
    </main>
</template>
EOT

cat <<EOT > resources/js/Pages/Index/Show.vue
<template>
    <main>
        <h3 class="mb-2 fw-bold">Show Page</h3>
        <p>Lorem ipsum dolor sit, amet consectetur adipisicing elit. Hic, nesciunt omnis accusamus et quisquam suscipit
            consectetur dicta non doloremque cum veritatis corrupti eveniet amet magnam, sed, obcaecati iure porro. Earum
            qui
            vitae expedita libero saepe voluptatem ab corporis suscipit rerum fugiat nam itaque deserunt incidunt quos
            optio,
            labore provident nisi.</p>
    </main>
</template>
EOT

cat <<EOT > resources/js/app.js
import './bootstrap'
import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/inertia-vue3'
import Main from './Layouts/Main.vue'

createInertiaApp({
    resolve: async (name) => {
        const pages = import.meta.glob('./Pages/**/*.vue')

        const page = await pages['./Pages/'+ name +'.vue']()
        page.default.layout = page.default.layout || Main

        return page
    },
    setup({ el, App, props, plugin }) {
        createApp({ render: () => h(App, props) })
            .use(plugin)
            .mount(el)
    },
})

EOT

# Step 8: Compile Assets and Start the Development Server
npm run build
php artisan serve
