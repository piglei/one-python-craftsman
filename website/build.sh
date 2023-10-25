#!/bin/bash
rm -rf public/*

antora antora-playbook.yml
cd public
mv book/latest/* .
sed -i 's#../../_/#/book/_/#g' *.html
