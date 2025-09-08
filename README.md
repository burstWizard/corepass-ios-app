# corepass - a cost effective digital hall pass solution

Thousands of schools in the US utilize digital hall pass systems and, on average, pay $3,000-$4,000 per year for the software. We believe this is too much money for a (relatively) simple software, so we seek to make a **MUCH** cheaper alternative. 

#### What is this repo?

This repo stores the code for the corepass digital ios app for students. Students can safely login (with Google), create new hallpasses, check on the status of unapproved hall passes, view active passes, and view past passes.

This app is written in Swift/SwiftUI, and is integrated with a Firebase Firestore database.

## Screens

### Login Screen
Students don't sign up - admin create accounts for them. Currently only supports sign in with Google, but we plan to support more.

<img src="https://raw.githubusercontent.com/burstWizard/corepass-ios-app/036d97af05023bf142defdabb7a904b1c9f500f2/readme-resources/sign_in.PNG" alt="Account View" height="300"/>

### Dashboard
Students can view active pass (if any), requested passes, and past passes. All data is fetched from firestore database.

#### Ex. Student with an Active Pass
<img src="https://raw.githubusercontent.com/burstWizard/corepass-ios-app/refs/heads/main/readme-resources/with_active.PNG
" alt="Account View" height="300"/>

#### Ex. Student with a Requested Pass
<img src="https://raw.githubusercontent.com/burstWizard/corepass-ios-app/refs/heads/main/readme-resources/with_requested.PNG" alt="Account View" height="300"/>


### Pass Detail view
Clicking full screen expands the active pass, which is useful for students to show hall pass monitors.
<img src="https://raw.githubusercontent.com/burstWizard/corepass-ios-app/refs/heads/main/readme-resources/PassDetailView.png" alt="Account View" height="300"/>



### New Pass Screen
<img src="https://raw.githubusercontent.com/burstWizard/corepass-ios-app/036d97af05023bf142defdabb7a904b1c9f500f2/readme-resources/newpass.PNG" alt="Account View" height="300"/>

#### Location Picker
Locations are fetched from a Firestore database

<img src="https://raw.githubusercontent.com/burstWizard/corepass-ios-app/036d97af05023bf142defdabb7a904b1c9f500f2/readme-resources/location_pick.PNG" alt="Account View" height="300"/>

### Account view
<img src="https://raw.githubusercontent.com/burstWizard/corepass-ios-app/036d97af05023bf142defdabb7a904b1c9f500f2/readme-resources/account.PNG" alt="Account View" height="300"/>
