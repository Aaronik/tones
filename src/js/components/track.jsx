import React from 'react'
import MiniMatrix from 'components/mini_matrix'
import TrackRemoveButton from 'components/track_remove_button'
import TrackBody from 'components/track_body'
import InstrumentSelector from 'components/instrument_selector'
import propTypes from 'js/prop_types'

const Track = React.createClass({
  propTypes: {
    track:             propTypes.track.isRequired,
    isActiveTrack:     React.PropTypes.bool.isRequired,
    activeColumn:      React.PropTypes.number.isRequired,
    activeSlotId:      React.PropTypes.number.isRequired,
    onRemoveTrack:     React.PropTypes.func.isRequired,
    onMiniMatrixClick: React.PropTypes.func.isRequired,
    onSlotClick:       React.PropTypes.func.isRequired,
    instruments:       React.PropTypes.array.isRequired, // TODO propTypes
    onInstrumentClick: React.PropTypes.func.isRequired,
    tunings:           React.PropTypes.array.isRequired, // TODO propTypes
    onTuningClick:     React.PropTypes.func.isRequired
  },

  render() {
    const { onMiniMatrixClick, onRemoveTrack, instruments, tunings } = this.props;
    const { id, tones, slots } = this.props.track;

    const onSlotClick       = this.props.onSlotClick.bind(null, id);
    const onInstrumentClick = this.props.onInstrumentClick.bind(null, id);
    const onTuningClick     = this.props.onTuningClick.bind(null, id);

    let containerClassName = 'track-container ';
    if (this.props.isActiveTrack) containerClassName += 'active';

    return (
      <div className={containerClassName}>

        <MiniMatrix
          tones={tones}
          activeColumn={this.props.activeColumn}
          onClick={onMiniMatrixClick.bind(null, id)}/>

        <InstrumentSelector
          activeInstrumentId={this.props.track.instrument.id}
          instruments={instruments}
          onInstrumentClick={onInstrumentClick}
          activeTuningId={this.props.track.tuning.id}
          tunings={tunings}
          onTuningClick={onTuningClick}/>

        <TrackBody
          slots={slots}
          activeSlotId={this.props.activeSlotId}
          onSlotClick={onSlotClick}/>

        <TrackRemoveButton onClick={onRemoveTrack.bind(null, id)}/>

      </div>
    )
  }
});

export default Track
