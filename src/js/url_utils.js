import _ from 'underscore'
import URL from 'url-parse'

import b2 from 'js/base2_converter'

window.URL = URL

// nab the URL from the nav bar
const url = () => {
  return new URL(window.location.toString(), true);
}

const navTo = (url) {
  window.history.pushState({}, '', url);
  window.postMessage('pushstate', '*');
}

// turn URL query string into list of tracks
function trackObjectsFromQuery (queryObj) {
  let trackObjects = [];
  let ids = Object.keys(queryObj);

  return ids.map( (id) => {
    let infoString = queryObj[id];
    let [encodedTones, encodedslots] = infoString.split('.');
    let tones = b2.decode(encodedTones, 256);
    let slots = b2.decode(encodedslots, 8);
    return { id, tones, slots };
  });
}

// turn URL into full state object, which will then
// be consumed by the UrlStore.
const deconstructUrlString = () => {
  var state = {},
      query = url().query;

  // active track
  state.activeTrackId = query.a;

  delete query.a; // make room for easy numerical deconstruction of tracks

  state.tracks = Object.keys(query).map(id => {
    const encodedToneBitString = query[id].split('.')[0],
          encodedSlotBitString = query[id].split('.')[1];

    const unencodedToneBitString = b2.decode(encodedToneBitString, 256), // TODO un hard code
          unencodedSlotBitString = b2.decode(encodedSlotBitString, 8);

    return {
      id: id,

      tones: unencodedToneBitString.split('').map((bit, id) => {
        return { id, active: bit === '1' };
      }),

      slots: unencodedSlotBitString.split('').map((bit, id) => {
        return { id, active: bit === '1' };
      })
  });

  return state;
};

const constructUrlString = (state) => {

  var query = { a: state.activeTrackId };

  state.tracks.forEach(track => {
    const unencodedToneBitString = track.tones.map(tone => {
      return tone.active ? '1' : '0';
    });

    const unencodedSlotBitString = track.slots.map(slot => {
      return slot.active ? '1' : '0';
    });

    const encodedToneBitString = b2.encode(unencodedToneBitString);
    const encodedSlotBitString = b2.encode(unencodedSlotBitString);

    query[track.id] = encodedToneBitString + '.' + encodedSlotBitString;
  });

  navTo(url().set('query', query).toString());
};

let utils = { deconstructUrlString, constructUrlString }

export default utils
