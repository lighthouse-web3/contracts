const {expect }= require('chai');
const { ethers } = require('hardhat');
const { array } = require('yargs');

let owner,Lighthouse,lighthouse;

beforeEach(async()=>{
    Lighthouse= await ethers.getContractFactory('Lighthouse');
    lighthouse= await Lighthouse.deploy();
    [owner]=await ethers.getSigners();
});

describe('LighthouseContract',()=>{
    it('Should set the right owner',async ()=>{
        expect(await lighthouse.owner()).to.equal(owner.address);
    });

    it('check',async ()=>{
        await lighthouse.store_test([[
            'hey',
            'cid',
            1,
            'cid',
            2,
            3
        ],[
            'hey',
            'cid',
            1,
            'cid',
            2,
            3
        ]],{
            value: ethers.utils.parseEther("1.0")
        });
    })

    it('Check the bundles',async ()=>{
        const provider= await ethers.getDefaultProvider();
        let balance;
        console.log(owner);
        await provider.getBalance(owner);
        // console.log("initial balance", await provider.getBalance(owner));


        const cid_bundles=[... Array(100).keys()].fill('cid',0,100);
        const config=[... Array(100).keys()].fill('config',0,100);
        const fileCost=[... Array(100).keys()];
        const fileName=[... Array(100).keys()].fill('fileName',0,100);
        const fileSize=[... Array(100).keys()];
        const timestamps=[... Array(100).keys()];

        const structarr=[];

        for(let i=0;i<100;++i){
            structarr.push([cid_bundles[i],config[i],fileCost[i],fileName[i],fileSize[i],timestamps[i]]);
        }
        console.log(structarr);
        let chunk=10;
        const length= structarr.length;
        console.log(length);
        for (let i = 0; i < length; i+=chunk) {
            const chunkarr = structarr.slice(i, i + chunk);

            await lighthouse.store_test(
                chunkarr
            ,{
                value: ethers.utils.parseEther("1.0")
            });
        }

        // console.log("Final Balance", await provider.getBalance(owner));



        // await lighthouse.store_test(
        //     structarr
        // ,{
        //     value: ethers.utils.parseEther("1.0")
        // });

    })
});