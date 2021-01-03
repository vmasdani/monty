// Additional JS script
app.ports.signOut.subscribe(() => {
    var auth2 = gapi.auth2.getAuthInstance();
    auth2.signOut().then(() => {
        console.log("Signed out.");

        app.ports.signedOut.send(null);
    });
});

function onSignIn(googleUser) {
    console.log("Google user:", googleUser);

    const basicProfile = googleUser.getBasicProfile();
    const idToken = googleUser.getAuthResponse().id_token;

    console.log("Basic profile:", basicProfile);
    console.log("ID token:", idToken);

    const data = {
        fullName: basicProfile.getName(),
        imageUrl: basicProfile.getImageUrl(),
        email: basicProfile.getEmail(),
        idToken: idToken,
    };

    console.log('User info:', data);

    app.ports.loggedIn.send(data);
}