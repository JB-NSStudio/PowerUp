#!/bin/bash

rm $(<.theos/last_package)
make package
cp .theos/_/usr/local/bin/IOPMKeyChecker ../bin/iopmcheck