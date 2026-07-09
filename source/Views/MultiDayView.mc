using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Application;

class MultiDayView extends WatchUi.View {
    var screenWidth;
    var screenHeight;
    var currentPage;

    function initialize() {
        View.initialize();
        currentPage = 1;
    }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, screenWidth, screenHeight);

        var app = Application.getApp();
        var multiData = app.dataManager.getMultiDayData();

        if (multiData == null || multiData.size() == 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(screenWidth / 2, screenHeight / 2, Graphics.FONT_SMALL,
                "Aucune donnée", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var idx = currentPage - 1;
        if (idx >= multiData.size()) { idx = multiData.size() - 1; }
        if (idx < 0) { idx = 0; }

        var dayData = multiData[idx];

        drawPageIndicator(dc, multiData.size());
        drawDayHeader(dc, dayData);
        var y = drawTideSummary(dc, dayData, 45);
        y = drawWaveSummary(dc, dayData, y);
        drawWindSummary(dc, dayData, y);
    }

    function drawPageIndicator(dc, total) {
        if (total <= 1) { return; }
        var dotSize = 5;
        var spacing = 12;
        var startX = (screenWidth - (total * spacing)) / 2 + spacing / 2;
        for (var i = 0; i < total; i++) {
            dc.setColor(i == currentPage - 1 ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY,
                Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(startX + i * spacing, 10, dotSize / 2);
        }
    }

    function drawDayHeader(dc, data) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth / 2, 20, Graphics.FONT_SMALL,
            data.dayLabel, Graphics.TEXT_JUSTIFY_CENTER);

        if (data.tide != null && data.tide.morningCoeff > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(screenWidth / 2, 40, Graphics.FONT_TINY,
                Lang.format("Coeff: $1$/$2$",
                    [data.tide.morningCoeff.format("%d"), data.tide.afternoonCoeff.format("%d")]),
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawTideSummary(dc, data, y) {
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(5, y, Graphics.FONT_TINY, "MARÉES", Graphics.TEXT_JUSTIFY_LEFT);
        y += 18;

        if (data.tide != null) {
            for (var i = 0; i < data.tide.events.size(); i++) {
                var event = data.tide.events[i];
                dc.setColor(event.type == 1 ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GREEN,
                    Graphics.COLOR_TRANSPARENT);
                dc.drawText(15, y, Graphics.FONT_TINY,
                    Lang.format("$1$ $2$ ($3$m)",
                        [event.getLabel(), event.getTimeString(), event.height.format("%.1f")]),
                    Graphics.TEXT_JUSTIFY_LEFT);
                y += 16;
            }
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(15, y, Graphics.FONT_TINY, "N/A", Graphics.TEXT_JUSTIFY_LEFT);
            y += 16;
        }
        return y + 3;
    }

    function drawWaveSummary(dc, data, y) {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(5, y, Graphics.FONT_TINY, "VAGUES", Graphics.TEXT_JUSTIFY_LEFT);
        y += 18;

        if (data.surf != null && data.surf.hourlyData.size() > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var minH = 99.0f;
            var maxH = 0.0f;
            for (var i = 0; i < data.surf.hourlyData.size(); i++) {
                var hr = data.surf.hourlyData[i];
                if (hr.waveHeight < minH) { minH = hr.waveHeight; }
                if (hr.waveHeight > maxH) { maxH = hr.waveHeight; }
            }
            dc.drawText(15, y, Graphics.FONT_TINY,
                Lang.format("Hauteur: $1$-$2$m", [minH.format("%.1f"), maxH.format("%.1f")]),
                Graphics.TEXT_JUSTIFY_LEFT);
            y += 16;

            for (var i = 0; i < data.surf.hourlyData.size(); i++) {
                var hr = data.surf.hourlyData[i];
                dc.setColor(getWaveColor(hr.waveHeight), Graphics.COLOR_TRANSPARENT);
                dc.drawText(15, y, Graphics.FONT_TINY,
                    Lang.format("$1$h: $2$m $3$ $4$s",
                        [hr.hour.format("%02d"), hr.waveHeight.format("%.1f"),
                         hr.swellDirection, hr.swellPeriod.format("%d")]),
                    Graphics.TEXT_JUSTIFY_LEFT);
                y += 16;
            }
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(15, y, Graphics.FONT_TINY, "N/A", Graphics.TEXT_JUSTIFY_LEFT);
            y += 16;
        }
        return y + 3;
    }

    function drawWindSummary(dc, data, y) {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(5, y, Graphics.FONT_TINY, "VENT", Graphics.TEXT_JUSTIFY_LEFT);
        y += 18;

        if (data.surf != null && data.surf.hourlyData.size() > 0) {
            for (var i = 0; i < data.surf.hourlyData.size(); i++) {
                var hr = data.surf.hourlyData[i];
                dc.setColor(getWindColor(hr.windSpeed), Graphics.COLOR_TRANSPARENT);
                dc.drawText(15, y, Graphics.FONT_TINY,
                    Lang.format("$1$h: $2$ $3$km/h $4$",
                        [hr.hour.format("%02d"), hr.windDirection,
                         hr.windSpeed.format("%d"), getWindBar(hr.windSpeed)]),
                    Graphics.TEXT_JUSTIFY_LEFT);
                y += 16;
            }
        }
        return y + 3;
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

    function prevPage() {
        if (currentPage > 1) {
            currentPage--;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function nextPage() {
        var app = Application.getApp();
        var multiData = app.dataManager.getMultiDayData();
        if (multiData != null && currentPage < multiData.size()) {
            currentPage++;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }
}

class MultiDayViewDelegate extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(view_) {
        BehaviorDelegate.initialize();
        view = view_;
    }

    function onSwipe(evt) {
        var direction = evt.getDirection();
        if (direction == WatchUi.SWIPE_LEFT) {
            return view.nextPage();
        }
        if (direction == WatchUi.SWIPE_RIGHT) {
            if (!view.prevPage()) {
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            }
            return true;
        }
        return false;
    }
}
