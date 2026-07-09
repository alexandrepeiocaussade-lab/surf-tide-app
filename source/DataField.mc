using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Application;

class SurfTideDataField extends WatchUi.DataField {
    var screenWidth;
    var screenHeight;

    function initialize() {
        DataField.initialize();
        label = "Surf&Tide";
    }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
    }

    function compute(info) {
        var app = Application.getApp();
        if (app != null && app.dataManager != null) {
            app.dataManager.fetchAllData();
        }
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, screenWidth, screenHeight);

        var app = Application.getApp();
        var today = (app != null && app.dataManager != null) ?
            app.dataManager.getTodayData() : null;

        if (today == null) {
            drawMinimal(dc);
            return;
        }

        var avgWave = (today.surf != null) ? today.surf.averageWaveHeight : 0.0f;
        var nextTide = getNextTide(today);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var mainLine = (avgWave > 0) ?
            Lang.format("~$1$m", [avgWave.format("%.1f")]) : "--m";
        dc.drawText(screenWidth / 2, screenHeight / 2 - 15,
            Graphics.FONT_SMALL, mainLine, Graphics.TEXT_JUSTIFY_CENTER);

        if (nextTide != null) {
            dc.setColor(nextTide.type == 1 ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GREEN,
                Graphics.COLOR_TRANSPARENT);
            var tideStr = Lang.format("$1$ $2$",
                [nextTide.getLabel(), nextTide.getTimeString()]);
            dc.drawText(screenWidth / 2, screenHeight / 2 + 8,
                Graphics.FONT_TINY, tideStr, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(screenWidth / 2, screenHeight / 2 + 8,
                Graphics.FONT_TINY, "Pas de marée", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawMinimal(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth / 2, screenHeight / 2 - 5,
            Graphics.FONT_SMALL, "S&T", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth / 2, screenHeight / 2 + 15,
            Graphics.FONT_TINY, "...", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function getNextTide(today) {
        if (today == null || today.tide == null) { return null; }

        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIA);

        var next = null;
        for (var i = 0; i < today.tide.events.size(); i++) {
            var event = today.tide.events[i];
            var eventMin = event.hour * 60 + event.minute;
            var nowMin = info.hour * 60 + info.min;
            if (eventMin > nowMin + 30) {
                if (next == null || eventMin < (next.hour * 60 + next.minute)) {
                    next = event;
                }
            }
        }
        return next;
    }
}
