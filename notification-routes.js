// Add this route after the existing API routes

// API endpoint to get recent messages for notifications
app.get('/api/notifications/messages', isAuthenticatedOrApiKey, async (req, res) => {
    try {
        const userId = req.user?.id || req.userId;
        const limit = parseInt(req.query.limit) || 10;
        
        const { data: messages, error } = await supabase
            .from('messages')
            .select('id, message, sender, chat_jid, timestamp, direction')
            .eq('user_id', userId)
            .eq('direction', 'in') // Only incoming messages for notifications
            .order('timestamp', { ascending: false })
            .limit(limit);
            
        if (error) {
            console.error('Error fetching messages:', error);
            return res.status(500).json({ error: 'Failed to fetch messages' });
        }
        
        // Format messages for notifications
        const notifications = messages.map(msg => ({
            id: msg.id,
            title: `New message from ${msg.sender}`,
            message: msg.message.length > 100 ? msg.message.substring(0, 100) + '...' : msg.message,
            sender: msg.sender,
            chat_jid: msg.chat_jid,
            timestamp: msg.timestamp,
            type: 'message',
            read: false // You can add a read status to the database if needed
        }));
        
        res.json({ success: true, notifications });
    } catch (error) {
        console.error('Error in notifications endpoint:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// API endpoint to get unread message count
app.get('/api/notifications/count', isAuthenticatedOrApiKey, async (req, res) => {
    try {
        const userId = req.user?.id || req.userId;
        
        // Get count of messages from last 24 hours
        const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
        
        const { count, error } = await supabase
            .from('messages')
            .select('id', { count: 'exact' })
            .eq('user_id', userId)
            .eq('direction', 'in')
            .gte('timestamp', twentyFourHoursAgo);
            
        if (error) {
            console.error('Error fetching message count:', error);
            return res.status(500).json({ error: 'Failed to fetch message count' });
        }
        
        res.json({ success: true, count: count || 0 });
    } catch (error) {
        console.error('Error in notifications count endpoint:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// API endpoint to get message details
app.get('/api/messages/:id', isAuthenticatedOrApiKey, async (req, res) => {
    try {
        const userId = req.user?.id || req.userId;
        const messageId = req.params.id;
        
        const { data: message, error } = await supabase
            .from('messages')
            .select('*')
            .eq('user_id', userId)
            .eq('id', messageId)
            .single();
            
        if (error) {
            console.error('Error fetching message:', error);
            return res.status(404).json({ error: 'Message not found' });
        }
        
        res.json({ success: true, message });
    } catch (error) {
        console.error('Error in message details endpoint:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

