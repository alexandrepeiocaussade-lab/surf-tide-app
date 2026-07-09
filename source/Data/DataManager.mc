using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;
using Toybox.Application;
using Toybox.Time;
using Toybox.WatchUi;

class DataManager {
    var settings;
    var currentData;
    var multiDayData;

    function initialize() {
        settings = new AppSettings();
        currentData = null;
        multiDayData = [];
        loadSettings();
    }

    function loadSettings() {
        var app = Application.getApp();
        var city = app.getProperty("selectedCity");
        var beach = app.getProperty("selectedBeach");
        var interval = app.getProperty("refreshInterval");

        if (city != null) { settings.selectedCity = city; }
        if (beach != null) { settings.selectedBeach = beach; }
        if (interval != null) { settings.refreshIntervalMinutes = interval; }
    }

    function saveSettings() {
        var app = Application.getApp();
        app.setProperty("selectedCity", settings.selectedCity);
        app.setProperty("selectedBeach", settings.selectedBeach);
        app.setProperty("refreshInterval", settings.refreshIntervalMinutes);
    }

    function fetchAllData() {
        var url = getProxyUrl() + "/api/combined";
        var params = {
            "city" => settings.selectedCity,
            "beach" => settings.selectedBeach
        };

        Communications.makeWebRequest(
            url,
            params,
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
                }
            },
            method(:onDataReceived)
        );
    }

    function onDataReceived(responseCode, data) {
        if (responseCode == 200 && data != null) {
            var parser = new ApiParser();
            multiDayData = parser.parseCombinedResponse(data);
            if (multiDayData != null && multiDayData.size() > 0) {
                currentData = multiDayData[0];
            }
            saveSettings();
            WatchUi.requestUpdate();
        } else {
            System.println("API Error: " + responseCode);
        }
    }

    function getProxyUrl() {
        return "https://surf-tide-app.onrender.com";
    }

    function getTodayData() {
        return currentData;
    }

    function getMultiDayData() {
        return multiDayData;
    }
}
