using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;

class SettingsView extends WatchUi.View {
    var screenWidth;
    var screenHeight;
    var cities;
    var beaches;
    var selectedCityIndex;
    var selectedBeachIndex;
    var editMode;

    function initialize() {
        View.initialize();
        cities = [
            "Biarritz", "Hossegor", "La Teste",
            "Biscarrosse", "Mimizan", "Contis",
            "Anglet", "Saint-Jean-de-Luz"
        ];
        beaches = [
            "Grande Plage", "Côte des Basques",
            "Plage d'Hossegor", "Plage Nord",
            "Plage Centrale", "Plage du Penon"
        ];
        selectedCityIndex = 0;
        selectedBeachIndex = 0;
        editMode = 0;
    }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
    }

    function onShow() {
        var app = Application.getApp();
        var savedCity = app.dataManager.settings.selectedCity;
        var savedBeach = app.dataManager.settings.selectedBeach;

        for (var i = 0; i < cities.size(); i++) {
            if (cities[i].equals(savedCity)) {
                selectedCityIndex = i;
                break;
            }
        }
        for (var i = 0; i < beaches.size(); i++) {
            if (beaches[i].equals(savedBeach)) {
                selectedBeachIndex = i;
                break;
            }
        }
        editMode = 0;
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, screenWidth, screenHeight);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth / 2, 10, Graphics.FONT_MEDIUM,
            "Paramètres", Graphics.TEXT_JUSTIFY_CENTER);

        var y = 50;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(10, y, Graphics.FONT_TINY, "Ville:", Graphics.TEXT_JUSTIFY_LEFT);
        y += 20;

        dc.setColor(editMode == 0 ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(15, y, Graphics.FONT_SMALL,
            cities[selectedCityIndex], Graphics.TEXT_JUSTIFY_LEFT);
        y += 30;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(10, y, Graphics.FONT_TINY, "Plage:", Graphics.TEXT_JUSTIFY_LEFT);
        y += 20;

        dc.setColor(editMode == 1 ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT);
        dc.drawText(15, y, Graphics.FONT_SMALL,
            beaches[selectedBeachIndex], Graphics.TEXT_JUSTIFY_LEFT);
        y += 40;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth / 2, y, Graphics.FONT_TINY,
            "Tap pour changer champ", Graphics.TEXT_JUSTIFY_CENTER);
        y += 20;
        dc.drawText(screenWidth / 2, y, Graphics.FONT_TINY,
            "↑↓ glisser valeur", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function toggleEditMode() {
        editMode = 1 - editMode;
        WatchUi.requestUpdate();
    }

    function selectNext() {
        if (editMode == 0) {
            selectedCityIndex = (selectedCityIndex + 1) % cities.size();
        } else {
            selectedBeachIndex = (selectedBeachIndex + 1) % beaches.size();
        }
        saveAndRefresh();
    }

    function selectPrev() {
        if (editMode == 0) {
            selectedCityIndex = (selectedCityIndex - 1 + cities.size()) % cities.size();
        } else {
            selectedBeachIndex = (selectedBeachIndex - 1 + beaches.size()) % beaches.size();
        }
        saveAndRefresh();
    }

    function saveAndRefresh() {
        var app = Application.getApp();
        app.dataManager.settings.selectedCity = cities[selectedCityIndex];
        app.dataManager.settings.selectedBeach = beaches[selectedBeachIndex];
        app.dataManager.saveSettings();
        WatchUi.requestUpdate();
    }
}

class SettingsViewDelegate extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(view_) {
        BehaviorDelegate.initialize();
        view = view_;
    }

    function onTap(evt) {
        view.toggleEditMode();
        return true;
    }

    function onSwipe(evt) {
        var direction = evt.getDirection();
        if (direction == WatchUi.SWIPE_UP) {
            view.selectNext();
            return true;
        }
        if (direction == WatchUi.SWIPE_DOWN) {
            view.selectPrev();
            return true;
        }
        if (direction == WatchUi.SWIPE_RIGHT) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return true;
        }
        return false;
    }
}
