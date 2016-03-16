<?php
/**
 * Testing procedure for WordPress Redis caching on Azure.
 */
global $group;

$group = isset( $_GET['group'] ) ? (int) $_GET['group'] : 1;

if ( ! defined( 'WP_CACHE_KEY_SALT' ) ) {
	define( 'WP_CACHE_KEY_SALT', 'memcached-test' );
}

require_once __DIR__ . '/wp-config.php';
require_once __DIR__ . '/content/object-cache.php';

/**
 * Output a table row for options.
 *
 * @param string $key The option key.
 */
function tr( $key ) {
	global $group;

	$val = wp_cache_get( $key, $group );
	printf(
		'<tr><td>%s</td><td>%s</td></tr>',
		$key,
		$val ? $val : '(n/a)'
	);
}

echo 'Initializing cache...';
wp_cache_init();
echo 'OK<br>';

echo '<br>Existing values<table><thead><tr><th>Key</th><th>Value</th></tr></thead><tbody>';
tr( 'add' );
tr( 'get' );
tr( 'replace' );
tr( 'delete' );
echo '</tbody></table><br>';

echo 'Adding objects to the cache...';
wp_cache_add( 'add', 'Added-' . $group, $group );
wp_cache_add( 'get', 'Got-' . $group, $group );
wp_cache_add( 'replace', 'Added-' . $group, $group );
wp_cache_add( 'delete', 'Deleted-' . $group, $group );
echo 'OK<br>';

echo 'Get a key...';
$get = wp_cache_get( 'get', $group );
echo 'Got-' . $group === $get ? 'OK' : 'FAIL';
echo '<br>';

echo 'Replace a key...';
wp_cache_replace( 'replace', 'Replaced-' . $group, $group );
$get = wp_cache_get( 'replace', $group );
echo 'Replaced-' . $group === $get ? 'OK' : 'FAIL';
echo '<br>';

echo 'Delete a key...';
wp_cache_delete( 'delete', $group );
$get = wp_cache_get( 'delete', $group );
echo ! $get ? 'OK' : 'FAIL';
echo '<br>';

echo '<br><br><a href="?group=' . (int) ( $group + 1 ) . '">Increment group</a>';
