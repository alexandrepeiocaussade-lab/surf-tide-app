using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Application;

class MainView extends WatchUi.View {
    var screenWidth;
    var screenHeight;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
    }

    function onShow() {
        var app = Application.getApp();
        app.dataManager.fetchAllData();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, screenWidth, screenHeight);

        var app = Application.getApp();
        var today = app.dataManager.getTodayData();

        if (today == null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(screenWidth / 2, screenHeight / 2 - 20, Graphics.FONT_SMALL,
                "Chargement...", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(screenWidth / 2, screenHeight / 2 + 10, Graphics.FONT_TINY,
                "Synchronisation", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        drawHeader(dc, today);
        var y = drawTideSection(dc, today, 50);
        y = drawSurfSection(dc, today, y);
        y = drawWindSection(dc, today, y);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth / 2, screenHeight - 5, Graphics.FONT_TINY,
            "Glisser pour + de jours", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawHeader(dc, data) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIA);
        var dayStr = Lang.format("$1$ $2$/$3$",
            [info.day_of_week, info.day.format("%02d"), info.month.format("%02d")]);

        dc.drawText(screenWidth / 2, 5, Graphics.FONT_MEDIUM,
            "Surf & Tide", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth / 2, 30, Graphics.FONT_TINY,
            dayStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawTideSection(dc, data, y) {
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(5, y, Graphics.FONT_TINY, "--- MARÉES ---", Graphics.TEXT_JUSTIFY_LEFT);
        y += 18;

        if (data.tide != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            if (data.tide.morningCoeff > 0) {
                dc.drawText(screenWidth / 2, y, Graphics.FONT_TINY,
                    Lang.format("Coeff: $1$/$2$",
                        [data.tide.morningCoeff.format("%d"), data.tide.afternoonCoeff.format("%d")]),
                    Graphics.TEXT_JUSTIFY_CENTER);
                y += 16;
            }
            for (var i = 0; i < data.tide.events.size(); i++) {
                var event = data.tide.events[i];
                dc.setColor(event.type == 1 ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GREEN,
                    Graphics.COLOR_TRANSPARENT);
                dc.drawText(12, y, Graphics.FONT_TINY,
                    Lang.format("$1$ $2$ ($3$m)",
                        [event.getLabel(), event.getTimeString(), event.height.format("%.1f")]),
                    Graphics.TEXT_JUSTIFY_LEFT);
                y += 16;
            }
            if (data.tide.events.size() == 0) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(12, y, Graphics.FONT_TINY, "Aucune donnée", Graphics.TEXT_JUSTIFY_LEFT);
                y += 16;
            }
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(12, y, Graphics.FONT_TINY, "Non disponible", Graphics.TEXT_JUSTIFY_LEFT);
            y += 16;
        }
        return y + 5;
    }

    function drawSurfSection(dc, data, y) {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(5, y, Graphics.FONT_TINY, "--- VAGUES ---", Graphics.TEXT_JUSTIFY_LEFT);
        y += 18;

        if (data.surf != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            if (data.surf.averageWaveHeight > 0) {
                dc.drawText(screenWidth / 2, y, Graphics.FONT_TINY,
                    Lang.format("Moy: $1$m", [data.surf.averageWaveHeight.format("%.1f")]),
                    Graphics.TEXT_JUSTIFY_CENTER);
                y += 18;
            }
            for (var i = 0; i < data.surf.hourlyData.size(); i++) {
                var hr = data.surf.hourlyData[i];
                dc.setColor(getWaveColor(hr.waveHeight), Graphics.COLOR_TRANSPARENT);
                dc.drawText(12, y, Graphics.FONT_TINY,
                    Lang.format("$1$h: $2$m $3$ $4$s",
                        [hr.hour.format("%02d"), hr.waveHeight.format("%.1f"),
                         hr.swellDirection, hr.swellPeriod.format("%d")]),
                    Graphics.TEXT_JUSTIFY_LEFT);
                y += 16;
            }
            if (data.surf.hourlyData.size() == 0) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(12, y, Graphics.FONT_TINY, "Aucune donnée vague", Graphics.TEXT_JUSTIFY_LEFT);
                y += 16;
            }
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(12, y, Graphics.FONT_TINY, "Non disponible", Graphics.TEXT_JUSTIFY_LEFT);
            y += 16;
        }
        return y + 5;
    }

    function drawWindSection(dc, data, y) {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(5, y, Graphics.FONT_TINY, "--- VENT ---", Graphics.TEXT_JUSTIFY_LEFT);
        y += 18;

        if (data.surf != null) {
            for (var i = 0; i < data.surf.hourlyData.size(); i++) {
                var hr = data.surf.hourlyData[i];
                dc.setColor(getWindColor(hr.windSpeed), Graphics.COLOR_TRANSPARENT);
                dc.drawText(12, y, Graphics.FONT_TINY,
                    Lang.format("$1$h: $2$ $3$km/h $4$",
                        [hr.hour.format("%02d"), hr.windDirection,
                         hr.windSpeed.format("%d"), getWindBar(hr.windSpeed)]),
                    Graphics.TEXT_JUSTIFY_LEFT);
                y += 16;
            }
        }
        return y + 5;
    }

    function getWaveColor(height) {
        if (height >= 2.0f) { return Graphics.COLOR_RED; }
        if (height >= 1.0f) { return Graphics.COLOR_ORANGE; }
        if (height >= 0.5f) { return Graphics.COLOR_YELLOW; }
        return Graphics.COLOR_LT_GRAY;
    }

    function getWindColor(speed) {
        if (speed >= 25) { return Graphics.COLOR_RED; }
        if (speed >= 15) { return Graphics.COLOR_ORANGE; }
        if (speed >= 8) { return Graphics.COLOR_GREEN; }
        return Graphics.COLOR_BLUE;
    }

    function getWindBar(speed) {
        var bars = "";
        var count = (speed / 5).toNumber();
        if (count > 5) { count = 5; }
        if (count < 1) { count = 1; }
        for (var i = 0; i < count; i++) { bars += "■"; }
        for (var i = count; i < 5; i++) { bars += "□"; }
        return bars;
    }
}

class MainViewDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSwipe(evt) {
        if (evt.getDirection() == WatchUi.SWIPE_LEFT) {
            var view = new MultiDayView();
            var delegate = new MultiDayViewDelegate(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
            return true;
        }
        if (evt.getDirection() == WatchUi.SWIPE_UP) {
            var view = new SettingsView();
            var delegate = new SettingsViewDelegate(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }
}
