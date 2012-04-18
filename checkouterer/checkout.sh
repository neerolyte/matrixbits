#!/bin/bash
USER="anonymous"
SERVER="public-cvs.squiz.net"
CVS_PUBLIC_PATH="/home/public"

# Allow the path to cvs to be overridden by an env var.
if [ "x$CVS" = "x" ]; then
	CVS="/usr/bin/cvs"
fi

if [ ! -x "$CVS" ]; then
	echo "No 'cvs' binary found at $CVS, aborting."
	exit 1
fi

print_usage()
{
	echo ""
	echo "This script will check out Squiz Matrix based on a version number you supply."
	echo "It will check out into a directory called 'squiz_matrix'."
	echo "Version numbers are based on releases. They are named the same way:"
	echo "mysource_4-x-y"
	echo "For example, if you want 4.0.4, the version number will be mysource_4-0-4"
	echo ""
	echo "So to use this script, it becomes:"
	echo "$0 mysource_4-0-4"
	echo ""
	echo "To install into a new directory, specify that as the second argument"
	echo "If this isn't specified, it will default to 'squiz_matrix'"
	echo "To do this, you must specify a version number to check out, eg:"
	echo "$0 mysource_4-0-4 squiz_matrix_4-0-4"
	exit 1
}

if [ "x$1" = "x" ]; then
	print_usage
	exit 1
fi

VERSION=$1

CHECKOUT_DIR="squiz_matrix"
if [ "x$2" != "x" ]; then
	CHECKOUT_DIR=$2
fi

if [ -d $CHECKOUT_DIR ]; then
	echo "Directory $CHECKOUT_DIR already exists, aborting."
	echo "Please specify a directory that doesn't exist."
	print_usage
	exit 1
fi

PACKAGES="bulkmail calendar cms data ecommerce filesystem funnelback google_maps import_tools ipb ldap news search sharepoint squid squiz_suite trim web_services"
FUDGE_PACKAGES="antivirus colour csv datetime_field db_extras dev file_versioning general image image_editor js_calendar ldap mollom rss_feeds standards_lists var_serialise wysiwyg"

echo "Checking out squiz matrix core .. "

$CVS -q -d :pserver:$USER:@$SERVER:$CVS_PUBLIC_PATH/core co -P -r $VERSION -d $CHECKOUT_DIR mysource_matrix > /dev/null

if [ $? -gt 0 ]; then
	echo "There was a problem checking out the matrix core"
	exit
fi

echo "Checking out squiz matrix packages .. "

cd $CHECKOUT_DIR/packages/

# these are done one by one because they are actually kept in separate repo's.
for package in $PACKAGES; do
	$CVS -q -d :pserver:$USER:@$SERVER:$CVS_PUBLIC_PATH/packages/$package co -P -r $VERSION $package > /dev/null
	if [ $? -gt 0 ]; then
		echo "There was a problem checking out the matrix package $package"
		echo "(Perhaps this package didn't exist with $VERSION)"
	fi
done

cd ../fudge/

# we can check everything out at once here because they are all just directories.
$CVS -q -d :pserver:$USER:@$SERVER:$CVS_PUBLIC_PATH/fudge co -P -r $VERSION $FUDGE_PACKAGES > /dev/null
if [ $? -gt 0 ]; then
	echo "There was a problem checking out the matrix 'fudge' $FUDGE_PACKAGES"
	echo "(Perhaps this package didn't exist with $VERSION)"
fi

cd ..

# Generate a manifest file for automatic_upgrades
# to work with.
find . -type f -not -path ./MANIFEST -a -not -path "*/CVS/*" -print0 | sort -z -k 2 | xargs -0 md5sum > ./MANIFEST
if [ $? -gt 0 ]; then
	echo "There was a problem generating the manifest file"
	exit
fi


echo ""
echo "Everything has been checked out into the $CHECKOUT_DIR/ folder."
echo "For installation instructions, please visit"
echo "http://matrix.squizsuite.net/quick-start-guide/manual-installation/"
echo ""

