# QR Scanner #
_
    <img src="https://user-images.githubusercontent.com/105886145/171826494-204c42e7-e5c5-4a36-80fe-6e806f59dc2c.gif"> 
        
    
### About ###
Swift/UIKit app for scanning QR codes

#### Features: ####
   - Scan QR codes in real time
   - Onscreen message with decoded string
   - If string is a date, indicates if day is public holiday (supported formats: "yyyy-MM-dd", "dd.MM.yyyy")
   - If string is an url, user can open it in browser

#### Technology stack: ####
  - Swift/UIKit
  - Architecture MVC
  - Dependencies with CocoaPods
  - Asynch HTTP requests to check a day's "holidayness"

### Installation ####
```sh
   cd .../QR-scanner
   pod install 
```
