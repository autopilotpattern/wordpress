<?php
/**
* Will be installed into mu-plugins when consul reports NFS container is not healthy
* Display an error when the NFS container is unavailable.
*/
function nfs_error_notice() {
?>

  <div class="error notice">
      <p><?php esc_html_e( 'The NFS container is not present, media uploads have been disabled'); ?></p>
  </div>

<?php
}
add_action( 'admin_notices', 'nfs_error_notice' );
