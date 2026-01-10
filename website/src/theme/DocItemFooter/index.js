import React from 'react';
import {useDoc} from '@docusaurus/theme-common/internal';

export default function DocItemFooterWrapper(props) {
  const {metadata} = useDoc();
  
  // Get timestamp and author
  const lastUpdatedAt = metadata?.lastUpdatedAt;
  const lastUpdatedBy = metadata?.lastUpdatedBy;

  // Format timestamp with seconds
  const formatTimestamp = (timestamp) => {
    if (!timestamp) return null;
    
    const date = new Date(timestamp * 1000); // Convert Unix timestamp to milliseconds
    
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    
    const month = months[date.getMonth()];
    const day = String(date.getDate()).padStart(2, '0');
    const year = date.getFullYear();
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    
    return `${month} ${day}, ${year} at ${hours}:${minutes}:${seconds}`;
  };

  const formattedTime = formatTimestamp(lastUpdatedAt);

  // Only render custom footer if we have timestamp data
  if (!formattedTime) {
    return null;
  }

  return (
    <div style={{
      marginTop: '2rem',
      paddingTop: '1rem',
      borderTop: '1px solid #e5e7eb',
      fontSize: '0.875rem',
      color: '#6b7280',
    }}>
      <p style={{margin: 0, fontWeight: '500'}}>
        📅 <strong>Last updated:</strong> {formattedTime}
        {lastUpdatedBy && <> by <strong>{lastUpdatedBy}</strong></>}
      </p>
    </div>
  );
}
