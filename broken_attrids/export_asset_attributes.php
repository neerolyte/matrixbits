<?php
/**
* @author David Schoen
* $ID$
*/

require_once dirname(dirname(dirname(__FILE__))).'/init.inc';
require_once SQ_FUDGE_PATH.'/general/file_system.inc';

$package = 'PACKAGE NAME HERE';
$export_dir = 'exported_attributes';

mkdir($export_dir) || trigger_error($export_dir.' dir exists!', E_USER_ERROR);

$asset_types = get_asset_types_for_package($package);



foreach ($asset_types as $type) {
	$ids = get_asset_ids_by_type($type);
	foreach ($ids as $id) {
		$attrs = get_asset_attributes($id);
		string_to_file(serialize($attrs),"$export_dir/$id");
	}
}









function get_asset_attributes($assetId) {
	$asset = $GLOBALS['SQ_SYSTEM']->am->getAsset($assetId);
	$attrs = array();

	foreach ($asset->vars as $attrName => $attrInfo) {
		$attrVal = $asset->attr($attrName);
		$attrs[$attrName] = $attrVal;
	}

	return $attrs;
}

function get_asset_ids_by_type($type_code) {
	$res = $GLOBALS['SQ_SYSTEM']->db->getAll("select assetid from sq_ast where type_code = '$type_code'");

	if (Pear::isError($res)) {
		trigger_error('failed to get assetids for type_code of '.$type_code, E_USER_ERROR);
	}

	$ids = array();
	foreach ($res as $row) {
		$ids []= $row['assetid'];
	}

	return $ids;
}


function get_asset_types_for_package($package) {
	require_once SQ_PACKAGES_PATH.'/'.$package.'/package_manager_'.$package.'.inc';

	$class = 'package_manager_'.$package;
	$pm =& new $class();

	$pm->_loadPackageAssets();

	return array_keys($pm->assets);
}
?>
