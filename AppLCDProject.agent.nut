//==============================================================================
// Created by Eddie Espinal (Nov 1st, 2014)
//==============================================================================

iPhoneAppID <- "388491656"
iPadAppID <- "587667052"

const REFRESH_TIME = 3600; // 1 hour
serverStatusLoopWakeup <- null;
release_date <- null;

function GetReleaseDateWithAppID(appID) {
    local url = "https://itunes.apple.com/us/app/fly-delta/id"+appID+"?mt=8";
    
    server.log("Inside GetReleaseDateFromURL");

    try {
        local result = http.get(url).sendsync();
        
        if (result.statuscode != 200) throw("Something went horribly wrong: " + result.statuscode + " - " + result.body);
        local data = result.body;

        if (data.len() == 1) return;

        local find_string = "<span class=\"label\">Updated: </span>"
        local index = 999
        //local release_date
        index = data.find(find_string)
        release_date = data.slice(index + find_string.len())
        release_date = release_date.slice(0, 12);

        server.log(release_date);

        return;
    } catch (ex) {
        server.log(ex);
        return;
    }
}

function GetiTunesDataWithAppID(appID) {
    local url = "https://itunes.apple.com/lookup?id="+appID;
    
    server.log("Inside GetiTunesData");

    try {
        local result = http.get(url).sendsync();
        
        if (result.statuscode != 200) throw("Something went horribly wrong: " + result.statuscode + " - " + result.body);
        local data = http.jsondecode(result.body);

        if (data.len() == 1) return;

        local appInfo = [];
        
        foreach (app in data.results)
        {
            server.log(app.artistName);
        
            appInfo.push({"appName" : app.trackName + " iPhone", "version" : app.version, "releaseDate" : release_date, "averageUserRatingForCurrentVersion": app.averageUserRatingForCurrentVersion, "userRatingCountForCurrentVersion" : app.userRatingCountForCurrentVersion, "userRatingCount" : app.userRatingCount, "minimumOsVersion" : app.minimumOsVersion, "bundleId" : app.bundleId, "averageUserRating" : app.averageUserRating});
        }
        
		//Send the device the info it needs to display on the LCD
        device.send("iTunesResponse", appInfo);

        return;
    } catch (ex) {
        server.log(ex);
        return;
    }
}

function serverStatusLoopWatchDog() {

    imp.wakeup(REFRESH_TIME - (time() % 60), serverStatusLoopWatchDog);

    server.log("Inside statusLoopWatchDog");
    
	//Since iTunes API doesn't return the release date for the current version, I had to hack it to scrape their website to find the correct date.
    GetReleaseDateWithAppID(iPhoneAppID);
    
    GetiTunesDataWithAppID(iPhoneAppID);
    
}

function onDeviceOn(_deviceId) {
    server.log("Device ID: " + _deviceId);
    server.log("Device On Called");
    
    serverStatusLoopWatchDog();
}

//Listen for when the device turns on.
device.on("deviceOn", onDeviceOn);

server.log("Agent Started");