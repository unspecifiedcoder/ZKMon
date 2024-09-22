import { Controller, Get } from '@nestjs/common';

/**
 * Default Route
 * / - uptime testing
 * /docs - documentation Link
 */
@Controller('/')
export class AppController {
  @Get()
  basicRoute(): object {
    return {
      welcome_msg:
        'GOOD Now struggle and figure out rest reading my /docs page ',
    };
  }
}
