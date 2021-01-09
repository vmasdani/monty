// Additional JS script
app.ports.signOut.subscribe(() => {
    var auth2 = gapi.auth2.getAuthInstance();
    auth2.signOut().then(() => {
        app.ports.signedOut.send(null);
    });
});

function onSignIn(googleUser) {
    const basicProfile = googleUser.getBasicProfile();
    const idToken = googleUser.getAuthResponse().id_token;

    const data = {
        fullName: basicProfile.getName(),
        imageUrl: basicProfile.getImageUrl(),
        email: basicProfile.getEmail(),
        idToken: idToken,
    };

    app.ports.loggedIn.send(data);
}
