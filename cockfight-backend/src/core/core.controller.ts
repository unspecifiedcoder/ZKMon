/* eslint-disable prettier/prettier */
// eslint-disable-next-line prettier/prettier
import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CoreService } from './core.service';

/**
 * core has two Routes for both SMS and Mobile
 * - core/query  - call it before every call or sms in coming to predict it as fraud or spam or normal
 * - core/muttate - call it for update or report a sms or number
 *
 * query rout must be called before incomming call or incoming msg which returns is a msg/sms is spam or ham or fraud and also related context
 *
 */

@Controller('core')
export class CoreController {
  constructor(private coreService: CoreService) {}

  @Get('getnewcock/:id')
  async query(@Param("id") id: number): Promise<string>  {
    return `bro you entered this ${id*0}`;
  }

  @Post('fight')
  async fight(@Body() body: any): Promise<string> {
    return "this.coreService.fight(body)";
  }

  @Post('breed')
  async breed(@Body() body: any): Promise<string> {
    return "this.coreService.breed(body)";
  }

  @Post('cross')
  async cross(@Body() body: any): Promise<string> {
    return "this.coreService.cross(body)";
  }
}
