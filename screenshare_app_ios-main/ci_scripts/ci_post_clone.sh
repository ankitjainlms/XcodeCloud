#!/bin/sh

#  ci_post_clone.sh
#  On24ScreenShare
#
#  Created by ADMIN on 13/06/24.
#  Copyright © 2024 TokBox, Inc. All rights reserved.
#!/bin/sh

# Install CocoaPods using Homebrew.


brew install cocoapods

# Install dependencies you manage with CocoaPods.

pod install
