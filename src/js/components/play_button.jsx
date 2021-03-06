import React from 'react'

const PlayButton = React.createClass({
  propTypes: {
    onClick: React.PropTypes.func.isRequired, // toggles
    active:  React.PropTypes.bool.isRequired
  },

  render() {
    const className = this.props.active ? 'fa fa-stop' : 'fa fa-play';
    return (
      <div onClick={this.props.onClick} className='play-button'>
        <i className={className}/>
      </div>
    );
  }
});

export default PlayButton
