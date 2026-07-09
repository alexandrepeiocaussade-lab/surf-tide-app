const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const NodeCache = require('node-cache');
const cors = require('cors');
require('dotenv').config();

const app = express();
const cache = new NodeCache({ stdTTL: 1800 }); // 30 min cache

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

// ============================================================
// CITY/BEACH CONFIGURATION
// ============================================================

const locations = {
    'Biarritz': {
        meteoconsult: 'https://www.meteoconsult.fr/marees/biarritz',
        surfReport: 'https://www.surf-report.com/meteo-surf/biarritz/',
        beaches: ['Grande Plage', 'Côte des Basques', 'Marbella']
    },
    'Hossegor': {
        meteoconsult: 'https://www.meteoconsult.fr/marees/hossegor',
        surfReport: 'https://www.surf-report.com/meteo-surf/hossegor/',
        beaches: ['Plage Centrale', 'Plage d\'Hossegor', 'La Gravière']
    },
    'Biscarrosse': {
        meteoconsult: 'https://www.meteoconsult.fr/marees/biscarrosse',
        surfReport: 'https://www.surf-report.com/meteo-surf/biscarrosse/',
        beaches: ['Plage Centrale', 'Plage Nord', 'Plage Sud']
    }
};

// ============================================================
// SCRAPING FUNCTIONS - meteoconsult.fr
// ============================================================

async function scrapeTideData(city) {
    const location = locations[city] || locations['Biarritz'];
    const url = location.meteoconsult;

    try {
        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
        });

        const $ = cheerio.load(response.data);
        const tideData = [];

        // Parse tide table - structure varies by site
        // This is adapted for meteoconsult.fr's typical structure
        $('.tide-table-day, .maree-jour, [class*="tide"]').each((i, element) => {
            const day = {
                date: $(element).find('.date, [class*="date"]').text().trim(),
                events: []
            };

            $(element).find('.tide-event, [class*="maree"], tr').each((j, event) => {
                const type = $(event).find('.type, [class*="type"]').text().trim().toLowerCase();
                const time = $(event).find('.time, [class*="heure"]').text().trim();
                const height = $(event).find('.height, [class*="hauteur"]').text().trim();
                const coeff = $(event).find('.coeff, [class*="coefficient"]').text().trim();

                if (time) {
                    const [hour, minute] = time.split('h').map(s => parseInt(s.trim()));
                    const isHigh = type.includes('pm') || type.includes('haute') || type.includes('high');

                    day.events.push({
                        type: isHigh ? 'high' : 'low',
                        hour: isNaN(hour) ? 0 : hour,
                        minute: isNaN(minute) ? 0 : minute,
                        height: parseFloat(height) || 0,
                        coefficient: parseInt(coeff) || 0
                    });
                }
            });

            if (day.events.length > 0) {
                tideData.push(day);
            }
        });

        return tideData;
    } catch (error) {
        console.error('Error scraping tide data:', error.message);
        return getMockTideData();
    }
}

// ============================================================
// SCRAPING FUNCTIONS - surf-report.com
// ============================================================

async function scrapeSurfData(city) {
    const location = locations[city] || locations['Biarritz'];
    const url = location.surfReport;

    try {
        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
        });

        const $ = cheerio.load(response.data);
        const surfData = [];

        // Parse surf forecast table
        $('.surf-day, .forecast-day, [class*="surf"], .day-forecast').each((i, element) => {
            const day = {
                date: $(element).find('.date, [class*="date"], .day-header').text().trim(),
                hours: []
            };

            $(element).find('.hour-row, .hour-block, [class*="hour"], tr.hour').each((j, hourEl) => {
                const hour = parseInt($(hourEl).find('.hour, [class*="heure"]').text().trim());
                const waveHeight = parseFloat(
                    $(hourEl).find('.wave-height, [class*="hauteur"], .wave').text().trim()
                );
                const swellDir = $(hourEl).find('.swell-dir, [class*="direction"], .dir').text().trim();
                const swellPeriod = parseInt(
                    $(hourEl).find('.swell-period, [class*="periode"], .period').text().trim()
                );
                const windDir = $(hourEl).find('.wind-dir, [class*="vent-dir"]').text().trim();
                const windSpeed = parseInt(
                    $(hourEl).find('.wind-speed, [class*="vent-force"], .wind').text().trim()
                );

                if (!isNaN(hour)) {
                    day.hours.push({
                        hour,
                        waveHeight: isNaN(waveHeight) ? 0 : waveHeight,
                        swellDirection: swellDir || 'N',
                        swellPeriod: isNaN(swellPeriod) ? 0 : swellPeriod,
                        windDirection: windDir || 'N',
                        windSpeed: isNaN(windSpeed) ? 0 : windSpeed,
                        windGusts: 0
                    });
                }
            });

            if (day.hours.length > 0) {
                surfData.push(day);
            }
        });

        if (surfData.length === 0) {
            console.log('No surf data parsed, using mock data');
            return getMockSurfData();
        }

        return surfData;
    } catch (error) {
        console.error('Error scraping surf data:', error.message);
        return getMockSurfData();
    }
}

// ============================================================
// MOCK DATA (fallback when scraping fails)
// ============================================================

function getMockTideData() {
    const today = new Date();
    const days = [];

    for (let d = 0; d < 7; d++) {
        const date = new Date(today);
        date.setDate(date.getDate() + d);
        const dateStr = date.toISOString().split('T')[0];
        const dayOfWeek = date.toLocaleDateString('fr-FR', { weekday: 'long' });

        // Simulate semi-diurnal tide (2 high, 2 low per day)
        const baseCoeff = 50 + Math.floor(Math.random() * 60);
        const events = [
            {
                type: 'low',
                hour: 6 + Math.floor(Math.random() * 2),
                minute: Math.floor(Math.random() * 60),
                height: 0.3 + Math.random() * 0.8,
                coefficient: baseCoeff
            },
            {
                type: 'high',
                hour: 12 + Math.floor(Math.random() * 2),
                minute: Math.floor(Math.random() * 60),
                height: 3.0 + Math.random() * 2.0,
                coefficient: baseCoeff + 10
            },
            {
                type: 'low',
                hour: 18 + Math.floor(Math.random() * 2),
                minute: Math.floor(Math.random() * 60),
                height: 0.4 + Math.random() * 0.7,
                coefficient: baseCoeff + 5
            },
            {
                type: 'high',
                hour: 0 + Math.floor(Math.random() * 2),
                minute: Math.floor(Math.random() * 60),
                height: 3.2 + Math.random() * 1.8,
                coefficient: baseCoeff + 15
            }
        ];

        // Sort by hour
        events.sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));

        days.push({
            date: dateStr,
            dayOfWeek,
            morningCoeff: baseCoeff,
            afternoonCoeff: baseCoeff + 10,
            events
        });
    }

    return days;
}

function getMockSurfData() {
    const today = new Date();
    const days = [];
    const swellDirs = ['NW', 'WNW', 'W', 'WSW', 'SW', 'SSW'];
    const windDirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

    for (let d = 0; d < 7; d++) {
        const date = new Date(today);
        date.setDate(date.getDate() + d);
        const dateStr = date.toISOString().split('T')[0];
        const hours = [];

        const baseWaveHeight = 0.5 + Math.random() * 2.0;

        for (let h = 6; h <= 22; h += 3) {
            const swellDir = swellDirs[Math.floor(Math.random() * swellDirs.length)];
            const windDir = windDirs[Math.floor(Math.random() * windDirs.length)];

            hours.push({
                hour: h,
                waveHeight: parseFloat((baseWaveHeight + (Math.random() - 0.5) * 0.8).toFixed(1)),
                swellDirection: swellDir,
                swellPeriod: Math.floor(8 + Math.random() * 8),
                windDirection: windDir,
                windSpeed: Math.floor(Math.random() * 35),
                windGusts: Math.floor(Math.random() * 45)
            });
        }

        days.push({
            date: dateStr,
            hours
        });
    }

    return days;
}

function combineData(tideData, surfData) {
    const combined = [];

    for (let i = 0; i < Math.max(tideData.length, surfData.length); i++) {
        const tide = tideData[i] || { date: '', events: [], morningCoeff: 0, afternoonCoeff: 0 };
        const surf = surfData[i] || { date: '', hours: [] };

        combined.push({
            date: tide.date || surf.date,
            tide: {
                morningCoeff: tide.morningCoeff || 0,
                afternoonCoeff: tide.afternoonCoeff || 0,
                events: tide.events || []
            },
            surf: {
                hours: surf.hours || []
            }
        });
    }

    return combined;
}

// ============================================================
// API ENDPOINTS
// ============================================================

app.get('/api/combined', async (req, res) => {
    const { city, beach } = req.query;
    const cacheKey = `combined_${city}_${beach}`;
    const cached = cache.get(cacheKey);

    if (cached) {
        return res.json({ days: cached });
    }

    try {
        const [tideData, surfData] = await Promise.all([
            scrapeTideData(city),
            scrapeSurfData(city)
        ]);

        const combined = combineData(tideData, surfData);
        cache.set(cacheKey, combined);

        res.json({ days: combined });
    } catch (error) {
        console.error('Combined API error:', error);
        // Fall back to mock data
        const tideData = getMockTideData();
        const surfData = getMockSurfData();
        const combined = combineData(tideData, surfData);

        res.json({ days: combined });
    }
});

app.get('/api/tide', async (req, res) => {
    const { city } = req.query;
    const cacheKey = `tide_${city}`;
    const cached = cache.get(cacheKey);

    if (cached) {
        return res.json({ days: cached });
    }

    const data = await scrapeTideData(city);
    cache.set(cacheKey, data);
    res.json({ days: data });
});

app.get('/api/surf', async (req, res) => {
    const { city } = req.query;
    const cacheKey = `surf_${city}`;
    const cached = cache.get(cacheKey);

    if (cached) {
        return res.json({ days: cached });
    }

    const data = await scrapeSurfData(city);
    cache.set(cacheKey, data);
    res.json({ days: data });
});

app.get('/api/cities', (req, res) => {
    const cityList = Object.keys(locations).map(name => ({
        name,
        beaches: locations[name].beaches
    }));
    res.json({ cities: cityList });
});

app.get('/health', (req, res) => {
    res.json({ status: 'ok', uptime: process.uptime() });
});

// ============================================================
// START SERVER
// ============================================================

app.listen(PORT, () => {
    console.log(`Surf&Tide Proxy Server running on port ${PORT}`);
    console.log(`Cities configured: ${Object.keys(locations).join(', ')}`);
});
