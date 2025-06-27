#!/usr/bin/env python3
"""
Discord Bot Entry Point

Main entry point for the Discord bot following 2025 best practices.
Uses Discord.py 2.5.2 with proper async patterns and Pydantic configuration.
"""

import asyncio
import logging
import signal
import sys
from contextlib import asynccontextmanager
from typing import AsyncGenerator

import discord
from discord.ext import commands

from src.config.settings import get_settings


class DiscordBot(commands.Bot):
    """Main Discord bot class with proper lifecycle management."""
    
    def __init__(self, settings) -> None:
        self.settings = settings
        
        # Configure intents - explicit for Discord.py 2.5.2
        intents = discord.Intents.default()
        intents.message_content = True  # Required for message commands
        intents.members = True  # Required for user management
        
        super().__init__(
            command_prefix=settings.command_prefix,
            intents=intents,
            case_insensitive=True,
            description="Discord Bot for Rocket League league management"
        )
        
        self._shutdown_event = asyncio.Event()
    
    async def setup_hook(self) -> None:
        """Called when the bot is starting up."""
        logging.info("Bot is starting up...")
        
        # Load cogs here when ready
        # await self.load_extension('src.cogs.tracker')
        # await self.load_extension('src.cogs.admin')
        
        logging.info(f"Bot setup complete. Logged in as {self.user}")
    
    async def on_ready(self) -> None:
        """Called when the bot is ready."""
        logging.info(f"Bot is ready! Logged in as {self.user} (ID: {self.user.id})")
        logging.info(f"Connected to {len(self.guilds)} guild(s)")
        
        # Sync application commands
        try:
            synced = await self.tree.sync()
            logging.info(f"Synced {len(synced)} command(s)")
        except Exception as e:
            logging.error(f"Failed to sync commands: {e}")
    
    async def on_command_error(self, ctx: commands.Context, error: commands.CommandError) -> None:
        """Global error handler for commands."""
        if isinstance(error, commands.CommandNotFound):
            return  # Ignore command not found errors
        
        if isinstance(error, commands.MissingRequiredArgument):
            await ctx.send(f"Missing required argument: {error.param.name}")
            return
        
        if isinstance(error, commands.BadArgument):
            await ctx.send(f"Invalid argument: {error}")
            return
        
        logging.error(f"Unhandled command error in {ctx.command}: {error}", exc_info=error)
        await ctx.send("An error occurred while processing your command.")
    
    async def close(self) -> None:
        """Gracefully close the bot."""
        logging.info("Bot is shutting down...")
        self._shutdown_event.set()
        await super().close()


@asynccontextmanager
async def create_bot(settings) -> AsyncGenerator[DiscordBot, None]:
    """Create and manage bot lifecycle."""
    bot = DiscordBot(settings)
    
    # Setup signal handlers for graceful shutdown
    def signal_handler(signum: int, frame) -> None:
        logging.info(f"Received signal {signum}, initiating shutdown...")
        asyncio.create_task(bot.close())
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        yield bot
    finally:
        if not bot.is_closed():
            await bot.close()


async def main() -> None:
    """Main entry point."""
    # Load settings
    settings = get_settings()
    
    # Configure logging
    logging.basicConfig(
        level=getattr(logging, settings.log_level.upper()),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    # Validate configuration
    if not settings.discord_token:
        logging.error("DISCORD_TOKEN is required")
        sys.exit(1)
    
    logging.info("Starting Discord bot...")
    logging.info(f"Environment: {settings.environment}")
    logging.info(f"Log level: {settings.log_level}")
    
    try:
        async with create_bot(settings) as bot:
            await bot.start(settings.discord_token)
    except KeyboardInterrupt:
        logging.info("Received keyboard interrupt, shutting down...")
    except Exception as e:
        logging.error(f"Unexpected error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logging.info("Bot stopped by user")
    except Exception as e:
        logging.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)