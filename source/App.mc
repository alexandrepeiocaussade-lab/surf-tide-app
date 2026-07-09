using Toybox.Application;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;
using Toybox.Communications;

class SurfTideApp extends Application.AppBase {

    var dataManager;

    function initialize() {
        AppBase.initialize();
        dataManager = new DataManager();
    }

    function onStart(state) {
        dataManager.loadSettings();
    }

    function onStop(state) {
        dataManager.saveSettings();
    }

    function getInitialView() {
        var mainView = new MainView();
        var delegate = new MainViewDelegate();
        return [mainView, delegate];
    }

    function getGoalViews() {
        var mainView = new MainView();
        var delegate = new MainViewDelegate();
        return [mainView, delegate];
    }

    function getGlanceView() {
        var mainView = new MainView();
        var delegate = new MainViewDelegate();
        return [mainView, delegate];
    }

    function getDataField() {
        return new SurfTideDataField();
    }
}

function getApp() {
    return Application.getApp();
}
