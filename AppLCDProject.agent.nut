/***********************************************************************************
 * Created by Eddie Espinal (Nov 1st, 2014)
 ***********************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Eddie Espinal
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 **********************************************************************************/

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
        
		local app = data.results[0];
		
		local appInfo = {
			appName = app.trackName, 
			version = app.version, 
			releaseDate = release_date, 
			averageUserRatingForCurrentVersion = app.averageUserRatingForCurrentVersion, 
			userRatingCountForCurrentVersion = app.userRatingCountForCurrentVersion, 
			userRatingCount = app.userRatingCount, 
			minimumOsVersion = app.minimumOsVersion, 
			bundleId = app.bundleId, 
			averageUserRating = app.averageUserRating
		};

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

//Listen for when the device turns on.
device.on("deviceOn", function(nullData) {
    server.log("Device On Called");
    serverStatusLoopWatchDog();
});

server.log("Agent Started");